import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/chat.dart';

enum ChatView { text, dial, video, full }

///好友或者群的消息控制器，包含某个连接的所有消息
class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;

  ///聊天界面的显示组件编号，0表示文本聊天界面，1表示视频通话拨出界面，2表示视频通话界面
  ///3表示全屏界面，可以前后浏览消息
  ChatView _chatView = ChatView.text;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  set chatSummary(ChatSummary? chatSummary) {
    if (_chatSummary != null &&
        chatSummary != null &&
        _chatSummary!.id == chatSummary.id) {
    } else {
      _chatSummary = chatSummary;
      _chatView = ChatView.text;
      clear();
    }
    previous(limit: defaultLimit);
  }

  ChatView get chatView {
    return _chatView;
  }

  set chatView(ChatView chatView) {
    if (_chatView != chatView) {
      _chatView = chatView;
      notifyListeners();
    }
  }

  modify(String peerId, {String? clientId}) {
    if (_chatSummary == null) {
      return;
    }
    if (_chatSummary!.peerId == peerId) {
      if (clientId == null ||
          _chatSummary!.clientId == null ||
          _chatSummary!.clientId == clientId) {
        notifyListeners();
      }
    }
  }

  ///访问数据库获取更老的消息
  @override
  Future<void> previous({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear();
      return;
    }
    if (chatSummary.peerId == null) {
      clear();
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

  ///访问数据库获取最新的消息
  @override
  Future<void> latest({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear();
      return;
    }
    if (chatSummary.peerId == null) {
      clear();
      return;
    }
    int? id;
    if (data.isNotEmpty) {
      id = data[0].id;
    }
    List<ChatMessage>? chatMessages;
    if (_chatSummary != null) {
      if (_chatSummary!.partyType == PartyType.linkman.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            peerId: _chatSummary!.peerId!, id: id, limit: limit);
      } else if (_chatSummary!.partyType == PartyType.group.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            groupPeerId: _chatSummary!.peerId!, id: id, limit: limit);
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
      ChatSubMessageType subMessageType = ChatSubMessageType.chat}) async {
    List<int>? data;
    if (message != null) {
      data = CryptoUtil.stringToUtf8(message);
    }
    return await send(
        title: title,
        data: data,
        contentType: contentType,
        mimeType: mimeType,
        subMessageType: subMessageType);
  }

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，取决于当前chatSummary
  Future<ChatMessage?> send(
      {String? title,
      List<int>? data,
      ContentType contentType = ContentType.text,
      String? mimeType,
      ChatSubMessageType subMessageType = ChatSubMessageType.chat}) async {
    if (_chatSummary == null) {
      return null;
    }
    String peerId = _chatSummary!.peerId!;
    String receiverName = _chatSummary!.name!;
    String? clientId = _chatSummary!.clientId;
    String partyType = _chatSummary!.partyType!;

    ChatMessage? chatMessage;
    if (partyType == PartyType.linkman.name) {
      //保存消息
      chatMessage = await chatMessageService.buildChatMessage(peerId,
          title: title,
          data: data,
          receiverName: receiverName,
          clientId: clientId,
          contentType: contentType,
          mimeType: mimeType,
          subMessageType: subMessageType);
      await chatMessageService.sendAndStore(chatMessage);
      notifyListeners();
    } else if (partyType == PartyType.group.name) {
      //保存群消息
      List<ChatMessage> chatMessages =
          await chatMessageService.buildGroupChatMessage(peerId,
              data: data,
              contentType: contentType,
              mimeType: mimeType,
              subMessageType: subMessageType);
      if (chatMessages.isNotEmpty) {
        chatMessage = chatMessages[0];
        for (var chatMessage in chatMessages.sublist(1)) {
          await chatMessageService.sendAndStore(chatMessage);
          await chatMessageService.store(chatMessage);
        }
      }
      notifyListeners();
    }
    return chatMessage!;
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChatMessageController chatMessageController = ChatMessageController();
