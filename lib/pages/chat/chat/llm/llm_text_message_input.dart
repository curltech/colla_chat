import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class TextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Future<void> Function()? onSendPressed;
  final void Function()? onEmojiPressed;
  final void Function()? onMorePressed;

  const TextMessageInputWidget({
    super.key,
    required this.textEditingController,
    this.onSendPressed,
    this.onEmojiPressed,
    this.onMorePressed,
  });

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

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
    llmChatMessageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///停止录音，把录音数据作为消息发送
  _onStop(String filename) async {
    if (StringUtil.isNotEmpty(filename)) {
      List<int>? data = await FileUtil.readFileAsBytes(filename);
      if (data == null) {
        return;
      }
      logger.i('record audio file: $filename length: ${data.length}');
      String? mimeType = FileUtil.mimeType(filename);
      await llmChatMessageController.send(
          content: data,
          title: FileUtil.filename(filename),
          contentType: ChatMessageContentType.audio,
          mimeType: mimeType,
          subMessageType: ChatMessageSubType.chat);
      // 发送保存结束后删除录音文件
      File file = File(filename);
      file.deleteSync();
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
    RecordAudioRecorderController audioRecorderController =
        globalRecordAudioRecorderController;
    audioRecorderController.encoder = AudioEncoder.aacLc;
    PlatformAudioRecorder platformAudioRecorder = PlatformAudioRecorder(
      onStop: _onStop,
      audioRecorderController: audioRecorderController,
    );

    return platformAudioRecorder;
  }

  bool _hasValue() {
    var value = widget.textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  Widget _buildLlmActionButton() {
    LlmAction llmAction = llmChatMessageController.llmAction;
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
          message: LlmAction.chat.name,
          child: const Icon(
            Icons.chat,
          )),
      Tooltip(
          message: LlmAction.translate.name,
          child: const Icon(
            Icons.translate,
          )),
      Tooltip(
          message: LlmAction.extract.name,
          child: const Icon(
            Icons.summarize_outlined,
          )),
      Tooltip(
        message: LlmAction.image.name,
        child: const Icon(
          Icons.image_outlined,
        ),
      ),
      Tooltip(
        message: LlmAction.audio.name,
        child: const Icon(
          Icons.multitrack_audio,
        ),
      ),
    ];

    return ToggleButtons(
        isSelected: isSelected,
        children: children,
        onPressed: (int index) {
          llmChatMessageController.llmAction = LlmAction.values[index];
        });
  }

  ///各种不同的ChatGPT的prompt的消息发送命令
  ///比如文本聊天，翻译，提取摘要，文本生成图片
  _onSend(BuildContext context, {LlmAction llmAction = LlmAction.chat}) async {
    llmChatMessageController.llmAction = llmAction;
    if (widget.onSendPressed != null) {
      widget.onSendPressed!();
      widget.textEditingController.clear();
    }
  }

  Widget _buildSendButton(BuildContext context) {
    Widget sendButton = Visibility(
        visible: _hasValue(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
          child: IconButton(
            tooltip: AppLocalizations.t('Send'),
            icon: Icon(Icons.send_outlined, color: myself.primary),
            onPressed: () {
              _onSend(context);
            },
          ),
        ));
    return sendButton;
  }

  ///文本，录音，其他消息，ChatGPT消息命令和发送按钮
  Widget _buildTextMessageInput(BuildContext context) {
    double iconInset = 0.0;
    return Card(
        elevation: 0.0,
        margin:
            EdgeInsets.symmetric(horizontal: iconInset, vertical: iconInset),
        shape: const ContinuousRectangleBorder(),
        child: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: IconButton(
              tooltip: voiceVisible
                  ? AppLocalizations.t('Voice')
                  : AppLocalizations.t('Keyboard'),
              icon: voiceVisible
                  ? Icon(Icons.record_voice_over_outlined,
                      color: myself.primary)
                  : Icon(Icons.keyboard_alt_outlined, color: myself.primary),
              onPressed: () {
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
            child: IconButton(
              tooltip: AppLocalizations.t('Emoji'),
              icon: Icon(Icons.emoji_emotions_outlined, color: myself.primary),
              onPressed: () {
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
                child: IconButton(
                  tooltip: AppLocalizations.t('More'),
                  icon: Icon(Icons.more_horiz, color: myself.primary),
                  onPressed: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
              )),
          _buildSendButton(context),
        ]));
  }

  ///语音录音按钮和文本输入框
  Widget _buildMessageInputWidget(BuildContext context) {
    List<Widget> children = [
      voiceVisible
          ? _buildExtendedTextField(context)
          : _buildVoiceRecordButton(context)
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget();
    if (parentWidget != null) {
      children.add(const SizedBox(
        height: 2,
      ));
      children.add(parentWidget);
    }
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
        alignment: Alignment.center,
        child: Column(children: children));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_update);
    llmChatMessageController.removeListener(_update);
    super.dispose();
  }
}
