import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///聊天界面的控制器
class ChatMessageViewController {
  static const double defaultChatMessageInputHeight = 48;
  static const double defaultEmojiMessageInputHeight = 270;
  static const double defaultMoreMessageInputHeight = 230;

  //输入消息的焦点
  final FocusNode focusNode = FocusNode();

  final RxDouble _chatMessageInputHeight = defaultChatMessageInputHeight.obs;
  final RxDouble _emojiMessageInputHeight = 0.0.obs;
  final RxDouble _moreMessageInputHeight = 0.0.obs;

  ///消息显示部分的高度
  double get chatMessageHeight {
    double bottomHeight = _chatMessageInputHeight.value + 8;
    if (emojiMessageInputHeight > 0) {
      bottomHeight = bottomHeight + _emojiMessageInputHeight.value;
    }
    if (moreMessageInputHeight > 0) {
      bottomHeight = bottomHeight + _moreMessageInputHeight.value;
    }
    double totalHeight = appDataProvider.portraitSize.height;
    if (appDataProvider.landscape) {
      totalHeight = appDataProvider.totalSize.height;
    }
    double chatMessageHeight = totalHeight -
        appDataProvider.toolbarHeight -
        bottomHeight -
        appDataProvider.topPadding -
        appDataProvider.bottomPadding +
        2;

    return chatMessageHeight;
  }

  ///输入框的高度可能发生变化，延时进行计算消息输入部分的高度
  void changeExtendedTextHeight(Size size) {
    double chatMessageInputHeight = size.height;
    if (_chatMessageInputHeight.value != chatMessageInputHeight) {
      _chatMessageInputHeight.value = chatMessageInputHeight;
      logger.i('chatMessageInputHeight: $_chatMessageInputHeight');
    }
  }

  double get chatMessageInputHeight {
    return _chatMessageInputHeight.value;
  }

  double get emojiMessageInputHeight {
    return _emojiMessageInputHeight.value;
  }

  set emojiMessageInputHeight(double emojiMessageInputHeight) {
    _emojiMessageInputHeight(emojiMessageInputHeight);
    logger.i('emojiMessageInputHeight: $_emojiMessageInputHeight');
    if (_emojiMessageInputHeight.value > 0) {
      _moreMessageInputHeight(0);
    }
  }

  double get moreMessageInputHeight {
    return _moreMessageInputHeight.value;
  }

  set moreMessageInputHeight(double moreMessageInputHeight) {
    _moreMessageInputHeight(moreMessageInputHeight);
    logger.i('moreMessageInputHeight: $_moreMessageInputHeight');
    if (_moreMessageInputHeight.value > 0) {
      _emojiMessageInputHeight(0);
    }
  }
}

final ChatMessageViewController chatMessageViewController =
    ChatMessageViewController();
