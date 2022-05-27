import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 展示的消息数据
class ChatMessageData {
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
  List<ChatMessageData> messages = [];

  ///这个方法需要被websocket的监听回调函数调用，把收到的信息处理后传过来
  void listenMessage(ChatMessageData message) {
    messages.insert(0, message);
    notifyListeners();
  }
}
