import 'dart:async';

import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/more_message_input.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';

import 'controller/chat_message_controller.dart';

///聊天消息的输入组件，
///第一行：包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
///第二行：emoji面板，其他多种格式输入面板
class ChatMessageInputWidget extends StatefulWidget {
  final double height;
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const ChatMessageInputWidget({Key? key, this.height = 270, this.onAction})
      : super(key: key);

  @override
  State createState() => _ChatMessageInputWidgetState();
}

class _ChatMessageInputWidgetState extends State<ChatMessageInputWidget> {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController = TextEditingController();
  bool emojiVisible = false;
  bool moreVisible = false;
  BlueFireAudioPlayer audioPlayer = BlueFireAudioPlayer();

  @override
  void initState() {
    super.initState();
    textEditingController.clear();
  }

  _update() {
    setState(() {});
  }

  _play() {
    audioPlayer.setLoopMode(false);
    audioPlayer.play('assets/medias/send.mp3');
  }

  _stop() {
    audioPlayer.stop();
  }

  ///发送文本消息
  Future<void> onSendPressed() async {
    _play();
    await chatMessageController.sendText(message: textEditingController.text);
  }

  void onEmojiPressed() {
    emojiVisible = !emojiVisible;
    if (emojiVisible) {
      moreVisible = false;
    }
    _update();
  }

  void onMorePressed() {
    moreVisible = !moreVisible;
    if (moreVisible) {
      emojiVisible = false;
    }
    _update();
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
    return Column(children: [
      SizedBox(
          height: 115,
          child: TextMessageInputWidget(
            textEditingController: textEditingController,
            onEmojiPressed: onEmojiPressed,
            onMorePressed: onMorePressed,
            onSendPressed: onSendPressed,
          )),
      Visibility(
          visible: emojiVisible,
          child: EmojiMessageInputWidget(
            onTap: _onEmojiTap,
            height: widget.height,
          )),
      Visibility(
          visible: moreVisible,
          child: MoreMessageInput(
            height: widget.height,
            onAction: widget.onAction,
          )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatMessageInput(context);
  }

  @override
  dispose() {
    super.dispose();
  }
}
