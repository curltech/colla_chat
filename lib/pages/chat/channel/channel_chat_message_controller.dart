import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/chat.dart';

///频道消息的消息控制器
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
    chatMessages = await chatMessageService.findByPeerId(
        peerId: myself.peerId!,
        messageType: ChatMessageType.channel.name,
        offset: data.length,
        limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
  }

  ///访问数据库获取最新的消息
  @override
  Future<void> latest({int? limit}) async {
    int? id;
    if (data.isNotEmpty) {
      id = data[0].id;
    }
    List<ChatMessage>? chatMessages = await chatMessageService.findByGreaterId(
        peerId: myself.peerId!,
        messageType: ChatMessageType.channel.name,
        id: id,
        limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
      notifyListeners();
    }
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChannelChatMessageController channelChatMessageController =
    ChannelChatMessageController();
