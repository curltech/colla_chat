import 'dart:async';

import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/more_message_input.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:flutter/material.dart';

///聊天消息的输入组件，
///第一行：包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
///第二行：emoji面板，其他多种格式输入面板
class ChatMessageInputWidget extends StatelessWidget {
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  late final EmojiMessageInputWidget emojiMessageInputWidget =
      EmojiMessageInputWidget(
    onTap: _onEmojiTap,
  );

  late final TextMessageInputWidget textMessageInputWidget =
      TextMessageInputWidget();

  late final MoreMessageInput moreMessageInput = MoreMessageInput(
    onAction: onAction,
  );

  ChatMessageInputWidget({super.key, this.onAction});

  _onEmojiTap(String text) {
    textMessageInputWidget.insertText(text);
  }

  Widget _buildChatMessageInput(BuildContext context) {
    List<Widget> children = [textMessageInputWidget];
    if (chatMessageViewController.emojiMessageInputHeight > 0) {
      children.add(emojiMessageInputWidget);
    }
    if (chatMessageViewController.moreMessageInputHeight > 0) {
      children.add(moreMessageInput);
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatMessageInput(context);
  }
}
