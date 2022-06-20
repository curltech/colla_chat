import 'package:flutter/material.dart';

import '../entity/chat/chat.dart';
import '../service/chat/chat.dart';

/// 接收到的消息列表状态管理器，维护了消息列表，当前消息
class ChatMessagesProvider with ChangeNotifier {
  List<ChatMessage> _chatMessages = [];
  int _currentIndex = 0;

  ChatMessagesProvider() {
    ChatMessageService.instance.findAllChatMessages().then((chatMessages) {
      _chatMessages.addAll(chatMessages);
      notifyListeners();
    });
  }

  List<ChatMessage> get chatMessages {
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

  ChatMessage get chatMessage {
    return _chatMessages[_currentIndex];
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int currentIndex) {
    _currentIndex = currentIndex;
    notifyListeners();
  }
}

var chatMessagesProvider = ChatMessagesProvider;
