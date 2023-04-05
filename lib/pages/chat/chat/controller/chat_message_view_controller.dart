import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

///聊天界面的控制器
class ChatMessageViewController with ChangeNotifier {
  static const double defaultChatMessageInputHeight = 48;
  static const double defaultEmojiMessageInputHeight = 270;
  static const double defaultMoreMessageInputHeight = 160;

  //输入消息的焦点
  final FocusNode focusNode = FocusNode();
  final GlobalKey<ExtendedTextFieldState> extendedTextKey =
      GlobalKey<ExtendedTextFieldState>();
  double _chatMessageInputHeight = defaultChatMessageInputHeight;
  double _emojiMessageInputHeight = 0;
  double _moreMessageInputHeight = 0;

  ///消息显示部分的高度
  double get chatMessageHeight {
    double bottomHeight = _chatMessageInputHeight + 12;
    if (chatMessageViewController.emojiMessageInputHeight > 0) {
      bottomHeight = bottomHeight + _emojiMessageInputHeight;
    }
    if (chatMessageViewController.moreMessageInputHeight > 0) {
      bottomHeight = bottomHeight + _moreMessageInputHeight;
    }
    var chatMessageHeight = appDataProvider.actualSize.height -
        appDataProvider.toolbarHeight -
        bottomHeight -
        25;

    return chatMessageHeight;
  }

  ///输入框的高度可能发生变化，延时进行计算消息输入部分的高度
  changeExtendedTextHeight() {
    Future.delayed(const Duration(milliseconds: 200), () {
      double? chatMessageInputHeight =
          extendedTextKey.currentContext?.size?.height;
      if (chatMessageInputHeight != null &&
          _chatMessageInputHeight != chatMessageInputHeight) {
        _chatMessageInputHeight = chatMessageInputHeight;
        notifyListeners();
      }
    });
  }

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
