import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:get/get.dart';

///收藏消息的消息控制器
class CollectionChatMessageController extends DataMoreController<ChatMessage> {
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
    List<ChatMessage> chatMessages = await chatMessageService.findByPeerId(
        peerId: myself.peerId!,
        messageType: ChatMessageType.collection.name,
        offset: data.length,
        limit: limit);
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
    List<ChatMessage> chatMessages = await chatMessageService
        .findByMessageType(ChatMessageType.collection.name, sendTime: sendTime);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
    }
    return chatMessages.length;
  }

  ///收藏变成消息
  collection() {
    chatMessageService.buildChatMessage();
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final CollectionChatMessageController collectionChatMessageController =
    CollectionChatMessageController();
