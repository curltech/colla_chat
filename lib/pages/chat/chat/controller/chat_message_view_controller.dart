import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///聊天界面的控制器
class ChatMessageViewController {
  static const double defaultChatMessageInputHeight = 48;
  static const double defaultEmojiMessageInputHeight = 270;
  static const double defaultMoreMessageInputHeight = 230;

  //输入消息的焦点
  final FocusNode focusNode = FocusNode();

  final ValueNotifier<double> chatMessageInputHeight =
      ValueNotifier<double>(defaultChatMessageInputHeight);
  final ValueNotifier<double> emojiMessageInputHeight =
      ValueNotifier<double>(0);
  final ValueNotifier<double> moreMessageInputHeight = ValueNotifier<double>(0);

  ///消息显示部分的高度
  double get chatMessageHeight {
    double bottomHeight = chatMessageInputHeight.value + 8;
    if (emojiMessageInputHeight.value > 0) {
      bottomHeight = bottomHeight + emojiMessageInputHeight.value;
    }
    if (moreMessageInputHeight.value > 0) {
      bottomHeight = bottomHeight + moreMessageInputHeight.value;
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
    if (this.chatMessageInputHeight.value != chatMessageInputHeight) {
      this.chatMessageInputHeight.value = chatMessageInputHeight;
      logger.i('chatMessageInputHeight: $chatMessageInputHeight');
    }
  }

  void setEmojiMessageInputHeight(double emojiMessageInputHeight) {
    this.emojiMessageInputHeight.value = emojiMessageInputHeight;
    logger.i('emojiMessageInputHeight: $emojiMessageInputHeight');
    if (this.emojiMessageInputHeight.value > 0) {
      moreMessageInputHeight.value = 0;
    }
  }

  void setMoreMessageInputHeight(double moreMessageInputHeight) {
    this.moreMessageInputHeight.value = moreMessageInputHeight;
    logger.i('moreMessageInputHeight: $moreMessageInputHeight.value');
    if (this.moreMessageInputHeight.value > 0) {
      emojiMessageInputHeight.value = 0;
    }
  }
}

final ChatMessageViewController chatMessageViewController =
    ChatMessageViewController();
