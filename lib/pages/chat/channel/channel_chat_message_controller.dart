import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/channel_chat_message.dart';
import 'package:colla_chat/service/chat/chat_message.dart';

///频道消息的消息控制器,自己订阅的,其他人发布的频道消息
class ChannelChatMessageController extends DataMoreController<ChatMessage> {
  String? _parentMessageId;

  String? get parentMessageId {
    return _parentMessageId;
  }

  set parentMessageId(String? parentMessageId) {
    if (_parentMessageId != parentMessageId) {
      _parentMessageId = parentMessageId;
      notifyListeners();
    }
  }

  ///访问数据库获取更老的消息
  @override
  Future<void> previous({int? limit}) async {
    List<ChatMessage>? chatMessages;
    chatMessages = await channelChatMessageService.findOthersByPeerId(
        offset: data.length, limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
  }

  ///访问数据库获取最新的消息
  @override
  Future<void> latest({int? limit}) async {
    String? sendTime;
    if (data.isNotEmpty) {
      sendTime = data[0].sendTime;
    }
    List<ChatMessage>? chatMessages = await channelChatMessageService
        .findOthersByGreaterId(sendTime: sendTime, limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
      notifyListeners();
    }
  }
}

///其他发布,自己订阅的频道消息
final ChannelChatMessageController channelChatMessageController =
    ChannelChatMessageController();

///自己发布的频道消息,消息的接收者是空的,在发送的时候填充接收者
class MyChannelChatMessageController extends DataMoreController<ChatMessage> {
  String? _parentMessageId;

  String? get parentMessageId {
    return _parentMessageId;
  }

  set parentMessageId(String? parentMessageId) {
    if (_parentMessageId != parentMessageId) {
      _parentMessageId = parentMessageId;
      notifyListeners();
    }
  }

  ///访问数据库获取更老的消息
  @override
  Future<void> previous({String? status, int? limit}) async {
    List<ChatMessage>? chatMessages;
    chatMessages = await channelChatMessageService.findMyselfByPeerId(
        status: status, offset: data.length, limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
  }

  ///访问数据库获取最新的消息
  @override
  Future<void> latest({String? status, int? limit}) async {
    String? sendTime;
    if (data.isNotEmpty) {
      sendTime = data[0].sendTime;
    }
    List<ChatMessage>? chatMessages =
        await channelChatMessageService.findMyselfByGreaterId(
            status: status, sendTime: sendTime, limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
      notifyListeners();
    }
  }

  store(String title, String content, List<int>? thumbnail) async {
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        title: title,
        content: content,
        thumbnail: thumbnail,
        messageType: ChatMessageType.channel,
        subMessageType: ChatMessageSubType.channel,
        transportType: TransportType.none,
        contentType: ChatMessageContentType.rich,
        status: MessageStatus.unsent.name,
        mimeType: ChatMessageMimeType.html);
    await chatMessageService.store(chatMessage);
  }

  publish(String messageId) async {
    await chatMessageService.update({'status': MessageStatus.published.name},
        where: 'messageId', whereArgs: [messageId]);
  }
}

///自己发布的频道消息
final MyChannelChatMessageController myChannelChatMessageController =
    MyChannelChatMessageController();
