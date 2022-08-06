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

  final Future<void> Function(String text)? onSend;

  const ChatMessageInputWidget(
      {Key? key, required this.textEditingController, this.onSend})
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

  Future<void> onSendPressed() async {
    if (widget.onSend != null) {
      widget.onSend!(widget.textEditingController.text);
    }
  }

  void onEmojiPressed() {
    emojiVisible = !emojiVisible;
    _update();
  }

  void onMorePressed() {
    moreVisible = !moreVisible;
    _update();
  }

  void _insertText(String text) {
    final TextEditingValue value = widget.textEditingController.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      widget.textEditingController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      widget.textEditingController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  _onEmojiTap(String text) {
    logger.i('Emoji: $text');
    _insertText(text);
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
        onSendPressed: onSendPressed,
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
