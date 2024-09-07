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
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/ollama/dart_ollama_client.dart';
import 'package:flutter/foundation.dart';
import 'package:get/state_manager.dart';
import 'package:uuid/uuid.dart';

enum LlmAction { chat, translate, extract, image, audio }

enum LlmLanguage { English, Chinese, French, German, Spanish, Japanese, Korean }

class LlmChatMessageController extends ChatMessageController {
  DartOllamaClient? dartOllamaClient;
  Rx<LlmAction> llmAction = LlmAction.chat.obs;
  Rx<LlmLanguage> llmLanguage = LlmLanguage.English.obs;
  Rx<LlmLanguage> targetLlmLanguage = LlmLanguage.English.obs;

  LlmChatMessageController();

  ///更新chatSummary，清空原数据，查询新数据
  @override
  set chatSummary(ChatSummary? chatSummary) {
    super.chatSummary = chatSummary;

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

  Future<void> llmChatAction(String content) async {
    var chatSummary = this.chatSummary;
    if (chatSummary == null) {
      return;
    }
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    PartyType? type = StringUtil.enumFromString(PartyType.values, partyType);
    type ??= PartyType.linkman;
    if (type == PartyType.linkman) {
      if (dartOllamaClient != null) {
        if (llmAction.value == LlmAction.translate) {
          content =
              "Please translate the following sentence from ${llmLanguage.value.name} to ${targetLlmLanguage.value.name}:'$content'";
        } else if (llmAction.value == LlmAction.audio) {
          content =
              "Please translate the following sentence to audio using a standard male voice:'$content'";
        }
        if (llmAction.value == LlmAction.chat ||
            llmAction.value == LlmAction.translate) {
          ChatMessage chatMessage = await chatMessageService.buildChatMessage(
              receiverPeerId: peerId,
              content: content,
              messageType: ChatMessageType.chat,
              contentType: ChatMessageContentType.text,
              subMessageType: ChatMessageSubType.chat,
              transportType: TransportType.llm);
          await chatMessageService.store(chatMessage);
          latest();
          String? chatResponse = await dartOllamaClient!.prompt(content);
          await onChatCompletion(chatResponse);
        }
      }
    }
  }

  onChatCompletion(String? chatResponse) async {
    ChatMessage chatMessage = buildLlmChatMessage(chatResponse,
        senderPeerId: chatSummary!.peerId, senderName: chatSummary!.name);
    await chatMessageService.store(chatMessage);
    latest();
  }

  ///接收到llm的消息回复
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
  }
}

final LlmChatMessageController llmChatMessageController =
    LlmChatMessageController();
