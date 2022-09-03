import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../../crypto/signalprotocol.dart';
import '../../../crypto/util.dart';
import '../../../entity/chat/chat.dart';
import '../../../entity/p2p/security_context.dart';
import '../../../plugin/logger.dart';
import '../../../service/chat/chat.dart';
import '../../../tool/util.dart';
import '../../../transport/webrtc/base_peer_connection.dart';

///跟踪影响全局的消息到来，对不同类型的消息进行分派
class GlobalChatMessageController with ChangeNotifier {
  ChatMessage? _chatMessage;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  ///跟踪影响全局的消息到来，对不同类型的消息进行分派
  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    if (chatMessage != null) {
      String peerId = chatMessage.senderPeerId!;
      String? clientId = chatMessage.senderClientId;
      String? title = chatMessage.title;
      String? content = chatMessage.content;
      if (content != null) {
        content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content));
      }
      ChatSubMessageType subMessageType = StringUtil.enumFromString(
          ChatSubMessageType.values, chatMessage.subMessageType!);
      logger.i(
          'chatMessage subMessageType:${subMessageType.name} title:$title content:$content');
      switch (subMessageType) {
        case ChatSubMessageType.videoChat:
          break;
        case ChatSubMessageType.chatReceipt:
          if (chatMessage.status == ChatReceiptType.agree.name) {
            //收到视频通话邀请同意回执，发出本地流，关闭拨号窗口VideoDialOutWidget，显示视频通话窗口VideoChatWidget
            videoChatReceiptController.chatReceipt = chatMessage;
          } else if (chatMessage.status == ChatReceiptType.reject.name) {
            //收到视频通话邀请拒绝回执，关闭本地流，关闭拨号窗口VideoDialOutWidget
            videoChatReceiptController.chatReceipt = chatMessage;
          }
          break;
        case ChatSubMessageType.preKeyBundle:
          _receivePreKeyBundle(chatMessage, content!);
          break;
        case ChatSubMessageType.audioChat:
          break;
        case ChatSubMessageType.signal:
          _receiveSignal(chatMessage, content!);
          break;
        default:
          break;
      }
      if (chatMessage.messageType != ChatMessageType.system.name) {
        chatMessageController.modify(peerId, clientId: clientId);
      }
    }
    notifyListeners();
  }

  ///收到signal加密初始化消息
  _receivePreKeyBundle(ChatMessage chatMessage, String content) async {
    String peerId = chatMessage.senderPeerId!;
    String? clientId = chatMessage.senderClientId;
    if (chatMessage.subMessageType == ChatSubMessageType.preKeyBundle.name) {
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
    String? clientId = chatMessage.senderClientId;
    if (chatMessage.subMessageType == ChatSubMessageType.signal.name) {
      WebrtcSignal webrtcSignal =
          WebrtcSignal.fromJson(JsonUtil.toJson(content));
      await peerConnectionPool.onWebrtcSignal(peerId, webrtcSignal,
          clientId: clientId);
    }
  }

  ///发送PreKeyBundle
  sendPreKeyBundle(String peerId, {String? clientId}) async {
    return;
    PreKeyBundle preKeyBundle =
        signalSessionPool.signalKeyPair.getPreKeyBundle();
    var json = signalSessionPool.signalKeyPair.preKeyBundleToJson(preKeyBundle);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(peerId,
        clientId: clientId,
        messageType: ChatMessageType.system,
        subMessageType: ChatSubMessageType.preKeyBundle,
        data: CryptoUtil.stringToUtf8(json));
    await chatMessageService.send(chatMessage,
        cryptoOption: CryptoOption.cryptography);
    logger.i('peerId: $peerId clientId:$clientId sent PreKeyBundle');
  }
}

///收到的最新消息
final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();
