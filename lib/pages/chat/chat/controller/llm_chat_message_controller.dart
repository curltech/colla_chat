import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/transport/ollama/dart_ollama_client.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum LlmAction { chat, image, audio, translate, extract }

class LlmChatMessageController extends ChatMessageController {
  DartOllamaClient? dartOllamaClient;
  LlmAction llmAction = LlmAction.chat;

  LlmChatMessageController() {
    transportType = TransportType.llm;
  }

  ///更新chatSummary，清空原数据，查询新数据
  @override
  set chatSummary(ChatSummary? chatSummary) {
    if (this.chatSummary != chatSummary) {
      if (chatSummary != null) {
        var peerId = chatSummary.peerId;
        linkmanService.findCachedOneByPeerId(peerId!).then((Linkman? linkman) {
          if (linkman != null) {
            if (linkman.linkmanStatus == LinkmanStatus.G.name) {
              dartOllamaClient = dartOllamaClientPool.get(linkman.peerId);
            } else {
              dartOllamaClient = null;
            }
          }
        });
      } else {
        dartOllamaClient = null;
      }
    }
    super.chatSummary = chatSummary;
  }

  Future<void> _llmChatAction(String content) async {
    if (llmAction == LlmAction.chat) {
      String? chatResponse = await dartOllamaClient!.prompt(content);
      await onChatCompletion(chatResponse);
    }
    // else if (llmAction == LlmAction.image) {
    //   String image = await langChainClient!.createImage(
    //     content,
    //   );
    //   onImageCompletion(image);
    // }
    // else if (langChainAction == LangChainAction.translate) {
    //   OpenAIAudioModel translation = await chatGPT!.createTranslation(
    //     file: File(''),
    //     prompt: content,
    //   );
    //   translation.text;
    // } else if (langChainAction == LangChainAction.audio) {
    //   File file = await chatGPT!.createSpeech(
    //     input: content,
    //   );
    // }
  }

  onChatCompletion(String? chatResponse) async {
    ChatMessage chatMessage = buildLlmChatMessage(chatResponse,
        senderPeerId: chatSummary!.peerId, senderName: chatSummary!.name);
    await chatMessageService.store(chatMessage);
    notifyListeners();
  }

  ///接收到chatGPT的消息回复
  ChatMessage buildLlmChatMessage(
    dynamic content, {
    String? senderPeerId,
    String? senderName,
    ChatMessageContentType contentType = ChatMessageContentType.text,
    ChatMessageMimeType mimeType = ChatMessageMimeType.text,
    String? parentMessageId,
  }) {
    ChatMessage chatMessage = ChatMessage();
    var uuid = const Uuid();
    chatMessage.messageId = uuid.v4();
    chatMessage.messageType = ChatMessageType.chat.name;
    chatMessage.subMessageType = ChatMessageSubType.chat.name;
    chatMessage.direct = ChatDirect.receive.name; //对自己而言，消息是属于发送或者接受
    chatMessage.senderPeerId = senderPeerId;
    chatMessage.senderType = PartyType.linkman.name;
    chatMessage.senderName = senderName;
    var current = DateUtil.currentDate();
    chatMessage.sendTime = current;
    chatMessage.readTime = current;

    ///把消息的接收者填写成自己myself
    chatMessage.receiverPeerId = myself.peerId;
    chatMessage.receiverType = PartyType.linkman.name;
    chatMessage.receiverClientId = myself.clientId;
    chatMessage.receiverName = myself.name;
    if (content is String) {
      chatMessage.content =
          CryptoUtil.encodeBase64(CryptoUtil.stringToUtf8(content));
    } else if (content is Uint8List) {
      chatMessage.content = CryptoUtil.encodeBase64(content);
    } else {
      chatMessage.content = content;
    }
    chatMessage.contentType = contentType.name;
    chatMessage.mimeType = mimeType.name;
    chatMessage.status = MessageStatus.received.name;
    chatMessage.transportType = TransportType.llm.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;
    chatMessage.id = null;

    return chatMessage;
  }

  onImageCompletion(String url) async {
    Uint8List content = await ImageUtil.loadUrlImage(url);
    ChatMessage chatMessage = buildLlmChatMessage(content,
        senderPeerId: chatSummary!.peerId,
        senderName: chatSummary!.name,
        contentType: ChatMessageContentType.image,
        mimeType: ChatMessageMimeType.png);
    await chatMessageService.store(chatMessage);
    notifyListeners();
  }
}

final LlmChatMessageController llmChatMessageController =
    LlmChatMessageController();
