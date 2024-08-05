import 'dart:async';

import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/more_message_input.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';

import 'controller/chat_message_controller.dart';

///聊天消息的输入组件，
///第一行：包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
///第二行：emoji面板，其他多种格式输入面板
class ChatMessageInputWidget extends StatelessWidget {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController = TextEditingController();

  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  late final EmojiMessageInputWidget emojiMessageInputWidget =
      EmojiMessageInputWidget(
    onTap: _onEmojiTap,
  );

  late final TextMessageInputWidget textMessageInputWidget =
      TextMessageInputWidget(
    textEditingController: textEditingController,
    onEmojiPressed: onEmojiPressed,
    onMorePressed: onMorePressed,
    onSendPressed: onSendPressed,
  );

  late final MoreMessageInput moreMessageInput = MoreMessageInput(
    onAction: onAction,
  );

  ChatMessageInputWidget({super.key, this.onAction});

  BlueFireAudioPlayer audioPlayer = globalBlueFireAudioPlayer;

  _play() {
    audioPlayer.setLoopMode(false);
    audioPlayer.play('assets/medias/send.mp3');
  }

  _stop() {
    audioPlayer.stop();
  }

  ///发送文本消息
  Future<void> onSendPressed() async {
    if (StringUtil.isNotEmpty(textEditingController.text)) {
      _play();
      await chatMessageController.sendText(message: textEditingController.text);
    }
  }

  void onEmojiPressed() {
    var height = chatMessageViewController.emojiMessageInputHeight;
    if (height == 0.0) {
      chatMessageViewController.emojiMessageInputHeight =
          ChatMessageViewController.defaultEmojiMessageInputHeight;
    } else {
      chatMessageViewController.emojiMessageInputHeight = 0.0;
    }
  }

  void onMorePressed() {
    var height = chatMessageViewController.moreMessageInputHeight;
    if (height == 0.0) {
      chatMessageViewController.moreMessageInputHeight =
          ChatMessageViewController.defaultMoreMessageInputHeight;
    } else {
      chatMessageViewController.moreMessageInputHeight = 0.0;
    }
  }

  void _insertText(String text) {
    final TextEditingValue value = textEditingController.value;
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

      textEditingController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      textEditingController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  _onEmojiTap(String text) {
    _insertText(text);
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
