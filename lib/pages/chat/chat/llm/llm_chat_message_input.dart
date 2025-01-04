import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/llm/llm_text_message_input.dart';
import 'package:flutter/material.dart';

///llm聊天消息的输入组件，
///第一行：包括扩展文本输入框，其他多种格式输入按钮和发送按钮
///第二行：其他多种格式输入面板
class LlmChatMessageInputWidget extends StatelessWidget {
  late final EmojiMessageInputWidget emojiMessageInputWidget =
      EmojiMessageInputWidget(
    onTap: _onEmojiTap,
  );

  late final LlmTextMessageInputWidget llmTextMessageInputWidget =
      LlmTextMessageInputWidget();

  LlmChatMessageInputWidget({super.key});

  _onEmojiTap(String text) {
    llmTextMessageInputWidget.insertText(text);
  }

  Widget _buildChatMessageInput(BuildContext context) {
    List<Widget> children = [llmTextMessageInputWidget];
    if (chatMessageViewController.emojiMessageInputHeight > 0) {
      children.add(emojiMessageInputWidget);
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatMessageInput(context);
  }
}
