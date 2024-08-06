import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/plugin/unicode_emoji_picker.dart';
import 'package:flutter/material.dart';

///Emoji文本消息的输入面板
class EmojiMessageInputWidget extends StatelessWidget {
  final Function(String text)? onTap;

  EmojiMessageInputWidget({
    super.key,
    required this.onTap,
  });

  final textEditingController = TextEditingController();
  final scrollController = ScrollController();

  _onBackspacePressed() {
    textEditingController
      ..text = textEditingController.text.characters.toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: textEditingController.text.length));
  }

  ///构造自定义的emoji的选择组件
  Widget _buildEmojiWidget(BuildContext context) {
    return UnicodeEmojiPicker(
        height: chatMessageViewController.emojiMessageInputHeight,
        onTap: onTap!);
  }

  @override
  Widget build(BuildContext context) {
    return _buildEmojiWidget(context);
  }
}
