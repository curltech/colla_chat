import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/channel_chat_message.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:get/get.dart';

///频道消息的消息控制器,自己订阅的,其他人发布的频道消息
class ChannelChatMessageController extends DataMoreController<ChatMessage> {
  final Rx<String?> _parentMessageId = Rx<String?>(null);

  String? get parentMessageId {
    return _parentMessageId.value;
  }

  set parentMessageId(String? parentMessageId) {
    _parentMessageId(parentMessageId);
  }

  ///访问数据库获取更老的消息
  @override
  Future<int> previous({int? limit}) async {
    List<ChatMessage> chatMessages = await channelChatMessageService
        .findOthersByPeerId(offset: data.length, limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
    return chatMessages.length;
  }

  ///访问数据库获取最新的消息
  @override
  Future<int> latest({int? limit}) async {
    String? sendTime;
    if (data.isNotEmpty) {
      sendTime = data[0].sendTime;
    }
    List<ChatMessage> chatMessages = await channelChatMessageService
        .findOthersByPeerId(sendTime: sendTime, limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
    }
    return chatMessages.length;
  }
}

///其他发布,自己订阅的频道消息
final ChannelChatMessageController channelChatMessageController =
    ChannelChatMessageController();

///自己发布的频道消息,消息的接收者是空的,在发送的时候填充接收者
class MyChannelChatMessageController extends DataMoreController<ChatMessage> {
  final Rx<String?> _parentMessageId = Rx<String?>(null);

  String? get parentMessageId {
    return _parentMessageId.value;
  }

  set parentMessageId(String? parentMessageId) {
    _parentMessageId(parentMessageId);
  }

  ///访问数据库获取更老的消息
  @override
  Future<int> previous({String? status, int? limit}) async {
    List<ChatMessage>? chatMessages;
    chatMessages = await channelChatMessageService.findMyselfByPeerId(
        status: status, offset: data.length, limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
    return chatMessages.length;
  }

  ///访问数据库获取最新的消息
  @override
  Future<int> latest({String? status, int? limit}) async {
    String? sendTime;
    if (data.isNotEmpty) {
      sendTime = data[0].sendTime;
    }
    List<ChatMessage>? chatMessages = await channelChatMessageService
        .findMyselfByPeerId(status: status, sendTime: sendTime, limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
    }
    return chatMessages.length;
  }

  Future<ChatMessage> buildChannelChatMessage(
      String title, String content, String? thumbnail,
      {ChatMessageMimeType mimeType = ChatMessageMimeType.html}) async {
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        title: title,
        content: content,
        thumbnail: thumbnail,
        messageType: ChatMessageType.channel,
        subMessageType: ChatMessageSubType.channel,
        transportType: TransportType.none,
        contentType: ChatMessageContentType.rich,
        status: MessageStatus.draft.name,
        mimeType: mimeType.name);

    return chatMessage;
  }

  Future<void> publish(String messageId) async {
    await chatMessageService.update(
        {
          'status': MessageStatus.published.name,
          'sendTime': DateUtil.currentDate(),
        },
        where: 'messageId=?',
        whereArgs: [messageId]);
  }
}

///自己发布的频道消息
final MyChannelChatMessageController myChannelChatMessageController =
    MyChannelChatMessageController();
