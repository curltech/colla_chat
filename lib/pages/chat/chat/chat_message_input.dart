import 'dart:async';
import 'dart:math';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/more_message_input.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../widgets/special_text/at_text.dart';
import '../../../widgets/special_text/custom_extended_text_selection_controls.dart';
import '../../../widgets/special_text/custom_special_text_span_builder.dart';
import '../../../widgets/special_text/dollar_text.dart';
import '../../../widgets/special_text/emoji_text.dart';

///聊天消息的输入组件，
///第一行：包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
///第二行：emoji面板，其他多种格式输入面板
class ChatMessageInputWidget extends StatefulWidget {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController;

  const ChatMessageInputWidget({Key? key, required this.textEditingController})
      : super(key: key);

  @override
  State createState() => _ChatMessageInputWidgetState();
}

class _ChatMessageInputWidgetState extends State<ChatMessageInputWidget> {
  final double height = 270;
  bool emojiVisible = false;
  bool moreVisible = false;

  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  void onSendPressed() {}

  void onEmojiPressed() {
    emojiVisible = !emojiVisible;
    _update();
  }

  void onMorePressed() {
    moreVisible = !moreVisible;
    _update();
  }

  _onEmojiTap(String text) {
    logger.i('Emoji: $text');
  }

  Widget _buildChatMessageInput(BuildContext context) {
    double height = this.height > appDataProvider.keyboardHeight
        ? this.height
        : appDataProvider.keyboardHeight;
    return Column(children: [
      TextMessageInputWidget(
        textEditingController: widget.textEditingController,
        onEmojiPressed: onEmojiPressed,
        onMorePressed: onMorePressed,
      ),
      Visibility(
          visible: emojiVisible,
          child: EmojiMessageInputWidget(
            onTap: _onEmojiTap,
            height: height,
          )),
      Visibility(
          visible: moreVisible,
          child: MoreMessageInput(
            height: height,
          )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatMessageInput(context);
  }
}
