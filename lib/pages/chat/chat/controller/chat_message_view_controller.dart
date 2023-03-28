import 'package:flutter/material.dart';

///聊天界面的控制器
class ChatMessageViewController with ChangeNotifier {
  //输入消息的焦点
  final FocusNode focusNode = FocusNode();
}

final ChatMessageViewController chatMessageViewController =
    ChatMessageViewController();
