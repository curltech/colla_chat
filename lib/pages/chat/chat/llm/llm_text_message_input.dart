import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class LlmTextMessageInputWidget extends StatelessWidget {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController = TextEditingController();

  ///文本录入按钮
  late final ExtendedTextMessageInputWidget extendedTextMessageInputWidget =
      ExtendedTextMessageInputWidget(
    textEditingController: textEditingController,
  );
  late final PlatformAudioRecorder platformAudioRecorder;

  LlmTextMessageInputWidget({
    super.key,
  }) {
    _buildVoiceRecordButton();
  }

  BlueFireAudioPlayer audioPlayer = globalBlueFireAudioPlayer;
  RxBool voiceVisible = true.obs;

  ///发送文本消息
  Future<void> onSendPressed() async {
    if (StringUtil.isNotEmpty(textEditingController.text)) {
      _play();
      await llmChatMessageController.llmChatAction(textEditingController.text);
    }
  }

  _play() {
    audioPlayer.setLoopMode(false);
    audioPlayer.play('assets/medias/send.mp3');
  }

  _stop() {
    audioPlayer.stop();
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

  void insertText(String text) {
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
    onSendPressed();
    textEditingController.clear();
  }

  Widget _buildSendButton(BuildContext context) {
    Widget sendButton = ListenableBuilder(
      listenable: textEditingController,
      builder: (BuildContext context, Widget? child) {
        return Visibility(
            visible: _hasValue(),
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
              child: IconButton(
                // tooltip: AppLocalizations.t('Send'),
                icon: Icon(Icons.send_outlined, color: myself.primary),
                onPressed: () {
                  _onSend(context);
                },
              ),
            ));
      },
    );

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
                onEmojiPressed();
              },
            ),
          ),
          ListenableBuilder(
              listenable: textEditingController,
              builder: (BuildContext context, Widget? child) {
                return Visibility(
                    visible: !_hasValue(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      child: IconButton(
                        // tooltip: AppLocalizations.t('More'),
                        icon: Icon(Icons.more_horiz, color: myself.primary),
                        onPressed: () {
                          onMorePressed();
                        },
                      ),
                    ));
              }),
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
