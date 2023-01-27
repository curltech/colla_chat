import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
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
  FocusNode textFocusNode = FocusNode();
  bool voiceVisible = true;
  bool sendVisible = false;
  bool moreVisible = false;
  bool voiceRecording = false;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
    chatMessageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  _onStop(String filename) async {
    if (StringUtil.isNotEmpty(filename)) {
      List<int>? data = await FileUtil.readFile(filename);
      if (data == null) {
        return;
      }
      logger.i('read file: $filename length: ${data.length}');
      String? mimeType = FileUtil.mimeType(filename);
      await chatMessageController.send(
          data: data,
          contentType: ContentType.audio,
          mimeType: mimeType,
          subMessageType: ChatMessageSubType.chat);
    }
  }

  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  Widget _buildVoiceRecordButton(context) {
    return PlatformAudioRecorder(
      onStop: _onStop,
    );
  }

  bool _hasValue() {
    var value = widget.textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  Widget _buildTextMessageInput(BuildContext context) {
    double iconInset = 2.0;
    return Container(
        margin:
            EdgeInsets.symmetric(horizontal: iconInset, vertical: iconInset),
        child: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
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
                  child: Icon(Icons.add_circle, color: myself.primary),
                  onTap: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
              )),
          Visibility(
              visible: _hasValue(),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: InkWell(
                  child: Icon(Icons.send, color: myself.primary),
                  onTap: () {
                    if (widget.onSendPressed != null) {
                      widget.onSendPressed!();
                      widget.textEditingController.clear();
                    }
                  },
                ),
              ))
        ]));
  }

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
