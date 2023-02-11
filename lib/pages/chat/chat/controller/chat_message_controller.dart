import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/chat.dart';

///好友或者群的消息控制器，包含某个连接的所有消息
class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;

  int _deleteTime = 0;
  String? _parentMessageId;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  ///更新chatSummary，清空原数据，查询新数据
  set chatSummary(ChatSummary? chatSummary) {
    if (_chatSummary != null &&
        chatSummary != null &&
        _chatSummary!.id == chatSummary.id) {
    } else {
      _chatSummary = chatSummary;
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
      ContentType contentType = ContentType.text,
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

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，取决于当前chatSummary
  ///先通过网络发送消息，然后保存在本地数据库
  Future<ChatMessage?> send(
      {String? title,
      dynamic content,
      ContentType contentType = ContentType.text,
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
    ChatMessage? chatMessage;
    if (partyType == PartyType.linkman.name) {
      peerIds ??= [];
      peerIds.add(peerId);
      for (var peerId in peerIds) {
        //保存消息
        chatMessage = await chatMessageService.buildChatMessage(
          peerId,
          title: title,
          content: content,
          contentType: contentType,
          mimeType: mimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          deleteTime: _deleteTime,
          parentMessageId: _parentMessageId,
        );
        chatMessage = await chatMessageService.sendAndStore(chatMessage);
        _deleteTime = 0;
        _parentMessageId = null;
      }
      notifyListeners();
    }
    if (partyType == PartyType.group.name) {
      //保存群消息
      List<ChatMessage> chatMessages =
          await chatMessageService.buildGroupChatMessage(
        peerId,
        messageId: messageId,
        content: content,
        contentType: contentType,
        mimeType: mimeType,
        subMessageType: subMessageType,
        deleteTime: _deleteTime,
        peerIds: peerIds,
      );
      _deleteTime = 0;
      if (chatMessages.isNotEmpty) {
        int i = 0;
        for (var chatMessage in chatMessages) {
          if (i == 0) {
            chatMessage = await chatMessageService.sendAndStore(chatMessage);
          } else {
            await chatMessageService.sendAndStore(chatMessage);
          }
          i++;
        }
        notifyListeners();
      }
    }
    return chatMessage!;
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChatMessageController chatMessageController = ChatMessageController();
