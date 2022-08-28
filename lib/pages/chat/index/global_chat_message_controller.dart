import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../../crypto/signalprotocol.dart';
import '../../../crypto/util.dart';
import '../../../entity/chat/chat.dart';
import '../../../entity/p2p/security_context.dart';
import '../../../plugin/logger.dart';
import '../../../service/chat/chat.dart';

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
      logger.i('chatMessage content:$content');
      if (chatMessage.subMessageType == ChatSubMessageType.videoChat.name) {
        if (title == null) {
          //收到视频通话邀请，显示拨入对话框VideoDialInWidget，indexView
        } else if (chatMessage.title == ChatReceiptType.agree.name) {
          //收到视频通话邀请同意回执，发出本地流，关闭拨号窗口VideoDialOutWidget，显示视频通话窗口VideoChatWidget
          localMediaController.chatReceipt = chatMessage;
        } else if (chatMessage.title == ChatReceiptType.reject.name) {
          //收到视频通话邀请拒绝回执，关闭本地流，关闭拨号窗口VideoDialOutWidget
          localMediaController.chatReceipt = chatMessage;
        }
      } else if (chatMessage.subMessageType ==
          ChatSubMessageType.audioChat.name) {
        if (title == null) {
          //收到音频通话邀请
        } else if (chatMessage.title == ChatReceiptType.agree.name) {
          //收到音频通话邀请同意回执
        } else if (chatMessage.title == ChatReceiptType.reject.name) {
          //收到音频通话邀请拒绝回执

        }
      } else if (chatMessage.subMessageType !=
          ChatSubMessageType.preKeyBundle.name) {
        _receivePreKeyBundle(chatMessage, content!);
      }
      if (chatMessage.subMessageType != ChatSubMessageType.preKeyBundle.name) {
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

  ///发送PreKeyBundle
  sendPreKeyBundle(String peerId,{String? clientId}) async {
    PreKeyBundle preKeyBundle =
        signalSessionPool.signalKeyPair.getPreKeyBundle();
    var json = signalSessionPool.signalKeyPair.preKeyBundleToJson(preKeyBundle);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        peerId,
        clientId: clientId,
        subMessageType: ChatSubMessageType.preKeyBundle,
        data: CryptoUtil.stringToUtf8(json));
    await chatMessageService.send(chatMessage,
        cryptoOption: CryptoOption.cryptography);
    logger.i(
        'peerId: $peerId clientId:$clientId sent PreKeyBundle');
  }
}

final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();
