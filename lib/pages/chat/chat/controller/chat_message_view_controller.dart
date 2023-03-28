import 'package:flutter/material.dart';

///聊天界面的控制器
class ChatMessageViewController with ChangeNotifier {
  static const double defaultChatMessageInputHeight = 58;
  static const double defaultEmojiMessageInputHeight = 270;
  static const double defaultMoreMessageInputHeight = 270;

  //输入消息的焦点
  final FocusNode focusNode = FocusNode();
  double _chatMessageInputHeight = defaultChatMessageInputHeight;
  double _emojiMessageInputHeight = 0;
  double _moreMessageInputHeight = 0;

  double get chatMessageInputHeight {
    return _chatMessageInputHeight;
  }

  set chatMessageInputHeight(double chatMessageInputHeight) {
    if (_chatMessageInputHeight != chatMessageInputHeight) {
      _chatMessageInputHeight = chatMessageInputHeight;
      notifyListeners();
    }
  }

  double get emojiMessageInputHeight {
    return _emojiMessageInputHeight;
  }

  set emojiMessageInputHeight(double emojiMessageInputHeight) {
    if (_emojiMessageInputHeight != emojiMessageInputHeight) {
      _emojiMessageInputHeight = emojiMessageInputHeight;
      if (_emojiMessageInputHeight > 0) {
        _moreMessageInputHeight = 0;
      }
      notifyListeners();
    }
  }

  double get moreMessageInputHeight {
    return _moreMessageInputHeight;
  }

  set moreMessageInputHeight(double moreMessageInputHeight) {
    if (_moreMessageInputHeight != moreMessageInputHeight) {
      _moreMessageInputHeight = moreMessageInputHeight;
      if (_moreMessageInputHeight > 0) {
        _emojiMessageInputHeight = 0;
      }
      notifyListeners();
    }
  }
}

final ChatMessageViewController chatMessageViewController =
    ChatMessageViewController();
