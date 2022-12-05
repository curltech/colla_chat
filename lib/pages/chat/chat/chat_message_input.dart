import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/more_message_input.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:flutter/material.dart';

///聊天消息的输入组件，
///第一行：包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
///第二行：emoji面板，其他多种格式输入面板
class ChatMessageInputWidget extends StatefulWidget {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController;

  final Future<void> Function(
      {String? message, ChatMessageSubType subMessageType})? onSend;

  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const ChatMessageInputWidget(
      {Key? key,
      required this.textEditingController,
      this.onSend,
      this.onAction})
      : super(key: key);

  @override
  State createState() => _ChatMessageInputWidgetState();
}

class _ChatMessageInputWidgetState extends State<ChatMessageInputWidget> {
  final double height = 270;
  bool emojiVisible = false;
  bool moreVisible = false;
  bool keyboardVisible = false;

  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Future<void> onSendPressed() async {
    if (widget.onSend != null) {
      widget.onSend!(message: widget.textEditingController.text);
    }
  }

  void onEmojiPressed() {
    if (keyboardVisible) {
      emojiVisible = false;
      moreVisible = false;
    } else {
      emojiVisible = !emojiVisible;
      if (emojiVisible) {
        moreVisible = false;
      }
      _update();
    }
  }

  void onMorePressed() {
    if (keyboardVisible) {
      emojiVisible = false;
      moreVisible = false;
    }
    moreVisible = !moreVisible;
    if (moreVisible) {
      emojiVisible = false;
    }
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
            onAction: widget.onAction,
          )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double keyboardHeight = mediaQueryData.viewInsets.bottom;
    if (keyboardHeight > 0) {
      keyboardVisible = true;
    }
    return _buildChatMessageInput(context);
  }

  @override
  dispose() {
    super.dispose();
  }
}
