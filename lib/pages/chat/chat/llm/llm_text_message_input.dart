import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
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

  final BlueFireAudioPlayer audioPlayer = globalBlueFireAudioPlayer;
  final RxBool voiceVisible = true.obs;

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

  Widget _buildLlmActionButton(BuildContext context) {
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
            fillColor: myself.primary,
            selectedColor: Colors.white,
            isSelected: isSelected,
            children: children,
            onPressed: (int index) {
              llmChatMessageController.llmAction.value =
                  LlmAction.values[index];
            }),
      );
    });
  }

  List<Widget> _getLlmLanguageIcons() {
    final List<Widget> children = [
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.English.name),
        child: Flag(Flags.united_states_of_america),
      ),
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.Chinese.name),
        child: Flag(Flags.china),
      ),
      Tooltip(
          message: AppLocalizations.t(LlmLanguage.French.name),
          child: Flag(Flags.france)),
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.German.name),
        child: Flag(Flags.germany),
      ),
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.Spanish.name),
        child: Flag(Flags.spain),
      ),
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.Japanese.name),
        child: Flag(Flags.japan),
      ),
      Tooltip(
        message: AppLocalizations.t(LlmLanguage.Korean.name),
        child: Flag(Flags.south_korea),
      ),
    ];

    return children;
  }

  Widget _buildLlmLanguageButton(BuildContext context) {
    return Obx(() {
      LlmLanguage llmLanguage = llmChatMessageController.llmLanguage.value;
      List<bool> isSelected = [];
      for (var ele in LlmLanguage.values) {
        if (ele == llmLanguage) {
          isSelected.add(true);
        } else {
          isSelected.add(false);
        }
      }

      return Center(
        child: ToggleButtons(
            borderRadius: BorderRadius.circular(16.0),
            fillColor: myself.primary,
            selectedColor: Colors.white,
            isSelected: isSelected,
            children: _getLlmLanguageIcons(),
            onPressed: (int index) {
              llmChatMessageController.llmLanguage.value =
                  LlmLanguage.values[index];
            }),
      );
    });
  }

  Widget _buildTargetLlmLanguageButton(BuildContext context) {
    return Obx(() {
      LlmLanguage llmLanguage =
          llmChatMessageController.targetLlmLanguage.value;
      List<bool> isSelected = [];
      for (var ele in LlmLanguage.values) {
        if (ele == llmLanguage) {
          isSelected.add(true);
        } else {
          isSelected.add(false);
        }
      }

      return Center(
        child: ToggleButtons(
            borderRadius: BorderRadius.circular(16.0),
            fillColor: myself.primary,
            selectedColor: Colors.white,
            isSelected: isSelected,
            children: _getLlmLanguageIcons(),
            onPressed: (int index) {
              llmChatMessageController.targetLlmLanguage.value =
                  LlmLanguage.values[index];
            }),
      );
    });
  }

  Widget _buildSettingWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(AppLocalizations.t('Action')),
          const SizedBox(
            width: 10.0,
          ),
          _buildLlmActionButton(context),
        ]),
        const SizedBox(
          height: 15.0,
        ),
        Row(children: [
          Text(AppLocalizations.t('Chat language')),
          const SizedBox(
            width: 10.0,
          ),
          _buildLlmLanguageButton(context),
        ]),
        const SizedBox(
          height: 15.0,
        ),
        Row(children: [
          Text(AppLocalizations.t('Target language')),
          const SizedBox(
            width: 10.0,
          ),
          _buildTargetLlmLanguageButton(context),
        ]),
        const Spacer(),
        Row(children: [
          const Spacer(),
          TextButton(
            style: StyleUtil.buildButtonStyle(
              backgroundColor: myself.primary,
              foregroundColor: Colors.white,
            ),
            child: CommonAutoSizeText(
              AppLocalizations.t('Ok'),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(
            width: 10.0,
          ),
        ]),
        const SizedBox(
          height: 15.0,
        ),
      ],
    );
  }

  Future<void> onSettingPressed(BuildContext context) async {
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: Container(
              height: 300,
              width: appDataProvider.secondaryBodyWidth,
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(15.0),
              child: _buildSettingWidget(context),
            ),
          );
        });
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
                        icon: Icon(Icons.settings, color: myself.primary),
                        onPressed: () {
                          onSettingPressed(context);
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
