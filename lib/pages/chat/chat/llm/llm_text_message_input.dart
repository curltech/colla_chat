import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class LlmTextMessageInputWidget extends StatelessWidget {
  final TextEditingController textEditingController;
  final Future<void> Function()? onSendPressed;
  final void Function()? onEmojiPressed;
  final void Function()? onMorePressed;

  ///文本录入按钮
  late final ExtendedTextMessageInputWidget extendedTextMessageInputWidget =
      ExtendedTextMessageInputWidget(
    textEditingController: textEditingController,
  );
  late final PlatformAudioRecorder platformAudioRecorder;

  LlmTextMessageInputWidget({
    super.key,
    required this.textEditingController,
    this.onSendPressed,
    this.onEmojiPressed,
    this.onMorePressed,
  }) {
    _buildVoiceRecordButton();
  }

  RxBool voiceVisible = true.obs;

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

  ///语音录音按钮
  Widget _buildVoiceRecordButton() {
    RecordAudioRecorderController audioRecorderController =
        globalRecordAudioRecorderController;
    audioRecorderController.encoder = AudioEncoder.aacLc;
    platformAudioRecorder = PlatformAudioRecorder(
      onStop: _onStop,
      audioRecorderController: audioRecorderController,
    );

    return platformAudioRecorder;
  }

  bool _hasValue() {
    var value = textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  ///各种不同的ChatGPT的prompt的消息发送命令
  ///比如文本聊天，翻译，提取摘要，文本生成图片
  _onSend(BuildContext context) async {
    if (onSendPressed != null) {
      onSendPressed!();
      textEditingController.clear();
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
            child: Obx(
              () {
                return IconButton(
                  // key: UniqueKey(),
                  // tooltip: voiceVisible.value
                  //     ? AppLocalizations.t('Voice')
                  //     : AppLocalizations.t('Keyboard'),
                  icon: voiceVisible.value
                      ? Icon(Icons.record_voice_over_outlined,
                          color: myself.primary)
                      : Icon(Icons.keyboard_alt_outlined,
                          color: myself.primary),
                  onPressed: () {
                    voiceVisible.value = !voiceVisible.value;
                  },
                );
              },
            ),
          ),
          Expanded(child: _buildMessageInputWidget(context)),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: IconButton(
              // key: UniqueKey(),
              // tooltip: AppLocalizations.t('Emoji'),
              icon: Icon(Icons.emoji_emotions_outlined, color: myself.primary),
              onPressed: () {
                if (onEmojiPressed != null) {
                  onEmojiPressed!();
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
                    if (onMorePressed != null) {
                      onMorePressed!();
                    }
                  },
                ),
              )),
          _buildSendButton(context),
        ]));
  }

  ///语音录音按钮和文本输入框
  Widget _buildMessageInputWidget(BuildContext context) {
    return Obx(
      () {
        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
            alignment: Alignment.center,
            child: voiceVisible.value
                ? extendedTextMessageInputWidget
                : platformAudioRecorder);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }
}
