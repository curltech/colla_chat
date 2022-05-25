import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatMessage {
  bool isMe = false;
  late String peerId;
  late String avatar;
  late String message;
  late DateTime messageTime;
}

/// 管理websocket接收到的消息，并进行状态管理
/// 访问方法：Provider
///         .of<WebsocketProvider>(context)
///         .messages;
class WebsocketProvider with ChangeNotifier {
  List<ChatMessage> messages = [];

  void listenMessage(ChatMessage message) {
    messages.insert(0, message);
    notifyListeners();
  }
}
