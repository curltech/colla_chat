import 'package:flutter/material.dart';

import '../entity/chat/chat.dart';
import '../service/chat/chat.dart';

/// 管理websocket接收到的消息，并进行状态管理
/// 访问方法：Provider
///         .of<WebsocketProvider>(context)
///         .messages;
class ChatMessageDataProvider with ChangeNotifier {
  List<ChatMessage> _chatMessages = [];
  bool initStatus = false;

  init() {
    ChatMessageService.instance.findAllChatMessages().then((chatMessages) {
      _chatMessages = chatMessages;
      initStatus = true;
      notifyListeners();
    });
  }

  List<ChatMessage> get chatMessages {
    if (!initStatus) {
      init();
    }
    return _chatMessages;
  }

  set chatMessages(List<ChatMessage> chatMessages) {
    _chatMessages = chatMessages;
    notifyListeners();
  }

  add(List<ChatMessage> chatMessages) {
    _chatMessages.addAll(chatMessages);
    notifyListeners();
  }
}
