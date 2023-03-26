import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/openai/openai_chat_gpt.dart';
import 'package:dart_openai/openai.dart';
import 'package:uuid/uuid.dart';

enum ChatGPTAction { chat, image, audio, translate, extract }

///好友或者群的消息控制器，包含某个连接的所有消息
class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;
  ChatGPT? chatGPT;
  ChatGPTAction chatGPTAction = ChatGPTAction.chat;
  int _deleteTime = 0;
  String? _parentMessageId;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  ///更新chatSummary，清空原数据，查询新数据
  set chatSummary(ChatSummary? chatSummary) {
    if (_chatSummary != chatSummary) {
      _chatSummary = chatSummary;
      if (_chatSummary != null) {
        var peerId = _chatSummary!.peerId;
        linkmanService.findCachedOneByPeerId(peerId!).then((Linkman? linkman) {
          if (linkman != null) {
            if (linkman.linkmanStatus == LinkmanStatus.chatGPT.name) {
              ChatGPT chatGPT = ChatGPT(linkman.peerId);
              chatGPT = chatGPT;
            } else {
              chatGPT = null;
            }
          }
        });
      } else {
        chatGPT = null;
      }
      clear(notify: false);
      previous(limit: defaultLimit);
    }
  }

  int get deleteTime {
    return _deleteTime;
  }

  set deleteTime(int deleteTime) {
    if (_deleteTime != deleteTime) {
      _deleteTime = deleteTime;
    }
  }

  String? get parentMessageId {
    return _parentMessageId;
  }

  set parentMessageId(String? parentMessageId) {
    if (_parentMessageId != parentMessageId) {
      _parentMessageId = parentMessageId;
      notifyListeners();
    }
  }

  ///访问数据库获取比当前数据更老的消息，如果当前数据为空，从最新的开始
  @override
  Future<void> previous({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear(notify: false);
      return;
    }
    if (chatSummary.peerId == null) {
      clear(notify: false);
      return;
    }
    List<ChatMessage>? chatMessages;
    if (_chatSummary != null) {
      if (_chatSummary!.partyType == PartyType.linkman.name) {
        chatMessages = await chatMessageService.findByPeerId(
            peerId: _chatSummary!.peerId!, offset: data.length, limit: limit);
      } else if (_chatSummary!.partyType == PartyType.group.name) {
        chatMessages = await chatMessageService.findByPeerId(
            groupPeerId: _chatSummary!.peerId!,
            offset: data.length,
            limit: limit);
      } else if (_chatSummary!.partyType == PartyType.conference.name) {
        chatMessages = await chatMessageService.findByPeerId(
            groupPeerId: _chatSummary!.peerId!,
            offset: data.length,
            limit: limit);
      }
      if (chatMessages != null && chatMessages.isNotEmpty) {
        addAll(chatMessages);
      }
    }
  }

  ///访问数据库获取比当前的最新的消息更新的消息
  @override
  Future<void> latest({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear(notify: false);
      return;
    }
    if (chatSummary.peerId == null) {
      clear(notify: false);
      return;
    }
    String? sendTime;
    if (data.isNotEmpty) {
      sendTime = data[0].sendTime;
    }
    List<ChatMessage>? chatMessages;
    if (_chatSummary != null) {
      if (_chatSummary!.partyType == PartyType.linkman.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            peerId: _chatSummary!.peerId!, sendTime: sendTime, limit: limit);
      } else if (_chatSummary!.partyType == PartyType.group.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            groupPeerId: _chatSummary!.peerId!,
            sendTime: sendTime,
            limit: limit);
      } else if (_chatSummary!.partyType == PartyType.conference.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            groupPeerId: _chatSummary!.peerId!,
            sendTime: sendTime,
            limit: limit);
      }
      if (chatMessages != null && chatMessages.isNotEmpty) {
        data.insertAll(0, chatMessages);
        notifyListeners();
      }
    }
  }

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，取决于当前chatSummary
  Future<ChatMessage?> sendText(
      {String? title,
      String? message,
      ChatMessageContentType contentType = ChatMessageContentType.text,
      String? mimeType,
      ChatMessageType messageType = ChatMessageType.chat,
      ChatMessageSubType subMessageType = ChatMessageSubType.chat,
      List<String>? peerIds}) async {
    return await send(
        title: title,
        content: message,
        contentType: contentType,
        mimeType: mimeType,
        messageType: messageType,
        subMessageType: subMessageType,
        peerIds: peerIds);
  }

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，也可以是会议，取决于当前chatSummary
  ///先通过网络发送消息，然后保存在本地数据库
  Future<ChatMessage?> send(
      {String? title,
      dynamic content,
      ChatMessageContentType contentType = ChatMessageContentType.text,
      String? mimeType,
      String? messageId,
      ChatMessageType messageType = ChatMessageType.chat,
      ChatMessageSubType subMessageType = ChatMessageSubType.chat,
      List<String>? peerIds}) async {
    if (_chatSummary == null) {
      return null;
    }
    String peerId = _chatSummary!.peerId!;
    String partyType = _chatSummary!.partyType!;
    PartyType? type = StringUtil.enumFromString(PartyType.values, partyType);
    if (type == null) {
      if (peerIds == null) {
        type = PartyType.linkman;
      } else {
        type = PartyType.group;
      }
    }
    ChatMessage returnChatMessage;
    ChatMessageMimeType? chatMessageMimeType =
        StringUtil.enumFromString<ChatMessageMimeType>(
            ChatMessageMimeType.values, mimeType);
    if (type == PartyType.linkman) {
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
          peerId,
          title: title,
          content: content,
          contentType: contentType,
          mimeType: chatMessageMimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          deleteTime: _deleteTime,
          parentMessageId: _parentMessageId);
      if (chatGPT == null) {
        returnChatMessage = await chatMessageService.sendAndStore(chatMessage);
      } else {
        await chatMessageService.store(chatMessage);
        returnChatMessage = chatMessage;
        if (chatGPTAction == ChatGPTAction.chat) {
          chatGPT!.chatCompletionStream(
            messages: [
              OpenAIChatCompletionChoiceMessageModel(
                  role: OpenAIChatMessageRole.user, content: content)
            ],
            onCompletion: onChatCompletion,
          );
        } else if (chatGPTAction == ChatGPTAction.image) {
          OpenAIImageModel openAIImageModel = await chatGPT!.createImage(
            prompt: content,
          );
          onImageCompletion(openAIImageModel);
        }
      }
    } else {
      List<ChatMessage> chatMessages =
          await chatMessageService.buildGroupChatMessage(peerId, type,
              title: title,
              content: content,
              contentType: contentType,
              mimeType: chatMessageMimeType,
              messageId: messageId,
              messageType: messageType,
              subMessageType: subMessageType,
              peerIds: peerIds,
              deleteTime: _deleteTime,
              parentMessageId: _parentMessageId);
      for (var chatMessage in chatMessages) {
        await chatMessageService.sendAndStore(chatMessage);
      }
      returnChatMessage = chatMessages[0];
    }
    _deleteTime = 0;
    _parentMessageId = null;
    notifyListeners();

    return returnChatMessage;
  }

  String completionContent = '';

  onChatCompletion(OpenAIStreamChatCompletionModel streamChatCompletion) async {
    if (streamChatCompletion.choices.isNotEmpty) {
      for (var choice in streamChatCompletion.choices) {
        String? finishReason = choice.finishReason;
        String? role = choice.delta.role;
        String? content = choice.delta.content;
        if (content != null && finishReason != 'stop') {
          if (content.startsWith('\n\n')) {
            completionContent = completionContent + content.substring(2);
          } else {
            completionContent = completionContent + content;
          }
          logger.i(content);
        } else {
          if (completionContent.isEmpty) {
            return;
          }
          ChatMessage chatMessage = buildChatGPTMessage(completionContent,
              senderPeerId: _chatSummary!.peerId,
              senderName: _chatSummary!.name);
          await chatMessageService.store(chatMessage);
          completionContent = '';
          notifyListeners();
        }
      }
    }
  }

  ChatMessage buildChatGPTMessage(
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
    chatMessage.transportType = TransportType.chatGPT.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;
    chatMessage.id = null;
    return chatMessage;
  }

  onImageCompletion(OpenAIImageModel openAIImageModel) async {
    if (openAIImageModel.data.isNotEmpty) {
      for (var openAIImageData in openAIImageModel.data) {
        String url = openAIImageData.url;
        Uint8List content = await ImageUtil.loadUrlImage(url);
        ChatMessage chatMessage = buildChatGPTMessage(content,
            senderPeerId: _chatSummary!.peerId,
            senderName: _chatSummary!.name,
            contentType: ChatMessageContentType.image,
            mimeType: ChatMessageMimeType.png);
        await chatMessageService.store(chatMessage);
      }
      notifyListeners();
    }
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChatMessageController chatMessageController = ChatMessageController();
