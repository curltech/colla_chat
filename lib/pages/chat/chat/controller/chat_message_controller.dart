import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/chat/peer_party.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/ollama/dart_ollama_client.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

enum LlmAction { chat, image, audio, translate, extract }

///好友或者群的消息控制器，包含某个连接的所有消息
class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;

  //发送方式
  TransportType transportType = TransportType.webrtc;

  //是否是llm聊天和chat方式
  DartOllamaClient? dartOllamaClient;
  LlmAction llmAction = LlmAction.chat;

  //调度删除时间
  int _deleteTime = 0;

  //引用的消息
  String? _parentMessageId;

  final Lock _lock = Lock();

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
      clear(notify: false);
      previous(limit: defaultLimit).then((int count) {
        if (count == 0) {
          notifyListeners();
        }
      });
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
  Future<int> previous({int? limit}) async {
    return _lock.synchronized(() async {
      var chatSummary = _chatSummary;
      if (chatSummary == null) {
        clear(notify: false);
        return 0;
      }
      if (chatSummary.peerId == null) {
        clear(notify: false);
        return 0;
      }
      List<ChatMessage>? chatMessages;
      if (_chatSummary != null) {
        if (_chatSummary!.partyType == PartyType.linkman.name) {
          int start = DateTime.now().millisecondsSinceEpoch;
          chatMessages = await chatMessageService.findByPeerId(
              peerId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              offset: data.length,
              limit: limit);
          int end = DateTime.now().millisecondsSinceEpoch;
          logger.i('chatMessageService.findByPeerId time:${end - start}');
        } else if (_chatSummary!.partyType == PartyType.group.name) {
          chatMessages = await chatMessageService.findByPeerId(
              groupId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              offset: data.length,
              limit: limit);
        } else if (_chatSummary!.partyType == PartyType.conference.name) {
          chatMessages = await chatMessageService.findByPeerId(
              groupId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              offset: data.length,
              limit: limit);
        }
        if (chatMessages != null && chatMessages.isNotEmpty) {
          addAll(chatMessages);

          return chatMessages.length;
        }
      }

      return 0;
    });
  }

  ///访问数据库获取比当前的最新的消息更新的消息
  @override
  Future<int> latest({int? limit}) async {
    return _lock.synchronized(() async {
      var chatSummary = _chatSummary;
      if (chatSummary == null) {
        clear(notify: false);
        return 0;
      }
      if (chatSummary.peerId == null) {
        clear(notify: false);
        return 0;
      }
      String? sendTime;
      if (data.isNotEmpty) {
        sendTime = data[0].sendTime;
      }
      List<ChatMessage>? chatMessages;
      if (_chatSummary != null) {
        if (_chatSummary!.partyType == PartyType.linkman.name) {
          chatMessages = await chatMessageService.findByGreaterId(
              peerId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              sendTime: sendTime,
              limit: limit);
        } else if (_chatSummary!.partyType == PartyType.group.name) {
          chatMessages = await chatMessageService.findByGreaterId(
              groupId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              sendTime: sendTime,
              limit: limit);
        } else if (_chatSummary!.partyType == PartyType.conference.name) {
          chatMessages = await chatMessageService.findByGreaterId(
              groupId: _chatSummary!.peerId!,
              messageType: ChatMessageType.chat.name,
              sendTime: sendTime,
              limit: limit);
        }
        if (chatMessages != null && chatMessages.isNotEmpty) {
          data.insertAll(0, chatMessages);
          notifyListeners();

          return chatMessages.length;
        }
      }

      return 0;
    });
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
      String? thumbnail,
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
    ChatMessage? returnChatMessage;
    if (type == PartyType.linkman) {
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
          receiverPeerId: peerId,
          title: title,
          content: content,
          thumbnail: thumbnail,
          contentType: contentType,
          mimeType: mimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          transportType: transportType,
          deleteTime: _deleteTime,
          parentMessageId: _parentMessageId);
      if (dartOllamaClient == null) {
        List<ChatMessage> returnChatMessages = await chatMessageService
            .sendAndStore(chatMessage, peerIds: peerIds);
        returnChatMessage = returnChatMessages.firstOrNull;
      } else {
        await chatMessageService.store(chatMessage);
        returnChatMessage = chatMessage;
        _llmChatAction(content);
      }
    } else {
      ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
          peerId, type,
          title: title,
          content: content,
          contentType: contentType,
          mimeType: mimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          transportType: transportType,
          deleteTime: _deleteTime,
          parentMessageId: _parentMessageId);
      List<ChatMessage> returnChatMessages =
          await chatMessageService.sendAndStore(chatMessage,
              cryptoOption: CryptoOption.group, peerIds: peerIds);
      returnChatMessage = returnChatMessages.firstOrNull;
    }
    _deleteTime = 0;
    _parentMessageId = null;
    transportType = TransportType.webrtc;
    notifyListeners();

    return returnChatMessage;
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
        senderPeerId: _chatSummary!.peerId, senderName: _chatSummary!.name);
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
    chatMessage.transportType = TransportType.chatGPT.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;
    chatMessage.id = null;

    return chatMessage;
  }

  onImageCompletion(String url) async {
    Uint8List content = await ImageUtil.loadUrlImage(url);
    ChatMessage chatMessage = buildLlmChatMessage(content,
        senderPeerId: _chatSummary!.peerId,
        senderName: _chatSummary!.name,
        contentType: ChatMessageContentType.image,
        mimeType: ChatMessageMimeType.png);
    await chatMessageService.store(chatMessage);
    notifyListeners();
  }

  Future<void> sendNameCard(List<String> peerIds) async {
    List<PeerParty> peers = [];
    String mimeType = PartyType.linkman.name;
    for (String peerId in peerIds) {
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      if (linkman != null) {
        peers.add(linkman);
      } else {
        Group? group = await groupService.findCachedOneByPeerId(peerId);
        if (group != null) {
          peers.add(group);
          mimeType = PartyType.group.name;
        }
      }
    }
    await chatMessageController.send(
        content: peers,
        contentType: ChatMessageContentType.card,
        mimeType: mimeType);
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChatMessageController chatMessageController = ChatMessageController();
