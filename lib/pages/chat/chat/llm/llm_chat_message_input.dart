import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/emoji_message_input.dart';
import 'package:colla_chat/pages/chat/chat/llm/llm_text_message_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    if (chatMessageViewController.moreMessageInputHeight > 0) {
      children.add(_buildLlmActionButton());
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: children);
  }

  Widget _buildLlmActionButton() {
    return Obx(() {
      LlmAction llmAction = llmChatMessageController.llmAction.value;
      List<bool> isSelected = [];
      for (var ele in LlmAction.values) {
        if (ele == llmAction) {
          isSelected.add(true);
        } else {
          isSelected.add(false);
        }
      }
      final List<Widget> children = [
        Tooltip(
            message: AppLocalizations.t(LlmAction.chat.name),
            child: const Icon(
              Icons.chat,
            )),
        Tooltip(
            message: AppLocalizations.t(LlmAction.translate.name),
            child: const Icon(
              Icons.translate,
            )),
        Tooltip(
            message: AppLocalizations.t(LlmAction.extract.name),
            child: const Icon(
              Icons.summarize_outlined,
            )),
        Tooltip(
          message: AppLocalizations.t(LlmAction.image.name),
          child: const Icon(
            Icons.image_outlined,
          ),
        ),
        Tooltip(
          message: AppLocalizations.t(LlmAction.audio.name),
          child: const Icon(
            Icons.multitrack_audio,
          ),
        ),
      ];
      return Center(
        child: ToggleButtons(
            borderRadius: BorderRadius.circular(16.0),
            fillColor: Colors.white,
            isSelected: isSelected,
            children: children,
            onPressed: (int index) {
              llmChatMessageController.llmAction.value =
                  LlmAction.values[index];
            }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatMessageInput(context);
  }
}
