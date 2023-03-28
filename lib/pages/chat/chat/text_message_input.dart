import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class TextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Future<void> Function()? onSendPressed;
  final void Function()? onEmojiPressed;
  final void Function()? onMorePressed;

  const TextMessageInputWidget({
    Key? key,
    required this.textEditingController,
    this.onSendPressed,
    this.onEmojiPressed,
    this.onMorePressed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TextMessageInputWidgetState();
  }
}

class _TextMessageInputWidgetState extends State<TextMessageInputWidget> {
  bool voiceVisible = true;
  bool sendVisible = false;
  bool moreVisible = false;
  bool voiceRecording = false;
  ValueNotifier<ChatGPTAction> chatGPTAction =
      ValueNotifier<ChatGPTAction>(ChatGPTAction.chat);

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
    chatMessageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///停止录音，把录音数据作为消息发送
  _onStop(String filename) async {
    if (StringUtil.isNotEmpty(filename)) {
      List<int>? data = await FileUtil.readFile(filename);
      if (data == null) {
        return;
      }
      logger.i('read file: $filename length: ${data.length}');
      String? mimeType = FileUtil.mimeType(filename);
      await chatMessageController.send(
          content: data,
          contentType: ChatMessageContentType.audio,
          mimeType: mimeType,
          subMessageType: ChatMessageSubType.chat);
    }
  }

  ///文本录入按钮
  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  ///语音录音按钮
  Widget _buildVoiceRecordButton(context) {
    return PlatformAudioRecorder(
      onStop: _onStop,
    );
  }

  bool _hasValue() {
    var value = widget.textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  List<ActionData> _buildChatGPTAction() {
    ChatGPTAction chatGPTAction = chatMessageController.chatGPTAction;
    final List<ActionData> chatGPTPopActionData = [
      ActionData(
          label: ChatGPTAction.chat.name,
          tooltip: 'Chat message',
          icon: Icon(
            Icons.chat,
            color: ChatGPTAction.chat == chatGPTAction ? myself.primary : null,
          )),
      ActionData(
          label: ChatGPTAction.translate.name,
          tooltip: 'Translate message',
          icon: Icon(
            Icons.translate,
            color: ChatGPTAction.translate == chatGPTAction
                ? myself.primary
                : null,
          )),
      ActionData(
          label: ChatGPTAction.extract.name,
          tooltip: 'Extract message',
          icon: Icon(
            Icons.summarize_outlined,
            color:
                ChatGPTAction.extract == chatGPTAction ? myself.primary : null,
          )),
      ActionData(
        label: ChatGPTAction.image.name,
        tooltip: 'Create image',
        icon: Icon(
          Icons.image_outlined,
          color: ChatGPTAction.image == chatGPTAction ? myself.primary : null,
        ),
      ),
      ActionData(
        label: ChatGPTAction.audio.name,
        tooltip: 'Transcription audio',
        icon: Icon(
          Icons.multitrack_audio,
          color: ChatGPTAction.audio == chatGPTAction ? myself.primary : null,
        ),
      ),
    ];

    return chatGPTPopActionData;
  }

  ///各种不同的ChatGPT的prompt的消息发送命令
  ///比如文本聊天，翻译，提取摘要，文本生成图片
  _onSend(BuildContext context, int index, String label,
      {String? value}) async {
    ChatGPTAction? chatGPTAction =
        StringUtil.enumFromString(ChatGPTAction.values, label);
    if (chatGPTAction == null) {
      return null;
    }
    chatMessageController.chatGPTAction = chatGPTAction;
    this.chatGPTAction.value = chatGPTAction;
    _send();
  }

  _send() {
    if (widget.onSendPressed != null) {
      widget.onSendPressed!();
      widget.textEditingController.clear();
    }
  }

  ///弹出ChatGPT的命令菜单
  _buildChatGPTMenu(BuildContext context) {
    Widget sendButton = Visibility(
        visible: _hasValue(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
          child: InkWell(
            child: Icon(Icons.send, color: myself.primary),
            onTap: () {
              _send();
            },
          ),
        ));

    ///长按弹出式菜单
    CustomPopupMenuController menuController = CustomPopupMenuController();
    Widget menu = MenuUtil.buildPopupMenu(
        child: sendButton,
        controller: menuController,
        menuBuilder: () {
          return Card(
            child: ValueListenableBuilder(
                valueListenable: chatGPTAction,
                builder: (BuildContext context, value, Widget? child) {
                  return DataActionCard(
                      onPressed: (int index, String label, {String? value}) {
                        menuController.hideMenu();
                        _onSend(context, index, label, value: value);
                      },
                      crossAxisCount: 4,
                      actions: _buildChatGPTAction(),
                      height: 140,
                      width: 320,
                      size: 20);
                }),
          );
        },
        pressType: PressType.longPress);

    return menu;
  }

  ///文本，录音，其他消息，ChatGPT消息命令和发送按钮
  Widget _buildTextMessageInput(BuildContext context) {
    double iconInset = 2.0;
    return Container(
        margin:
            EdgeInsets.symmetric(horizontal: iconInset, vertical: iconInset),
        child: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset * 3, vertical: iconInset),
            child: InkWell(
              child: voiceVisible
                  ? Icon(Icons.record_voice_over, color: myself.primary)
                  : Icon(Icons.keyboard, color: myself.primary),
              onTap: () {
                setState(() {
                  voiceVisible = !voiceVisible;
                });
              },
            ),
          ),
          Expanded(child: _buildMessageInputWidget(context)),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: InkWell(
              child: Icon(Icons.emoji_emotions, color: myself.primary),
              onTap: () {
                if (widget.onEmojiPressed != null) {
                  widget.onEmojiPressed!();
                }
              },
            ),
          ),
          Visibility(
              visible: !_hasValue(),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: InkWell(
                  child: Icon(Icons.add_circle_outline, color: myself.primary),
                  onTap: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
              )),
          _buildChatGPTMenu(context),
        ]));
  }

  ///语音录音按钮和文本输入框
  Widget _buildMessageInputWidget(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
        child: Column(children: [
          voiceVisible
              ? _buildExtendedTextField(context)
              : _buildVoiceRecordButton(context),
          const SizedBox(
            height: 2,
          ),
          MessageWidget.buildParentChatMessageWidget()
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_update);
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
