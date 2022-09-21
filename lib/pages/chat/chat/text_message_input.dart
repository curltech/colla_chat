import 'dart:async';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/audio/audio_waveforms_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/audio/platform_sound.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'extended_text_message_input.dart';

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
  String voiceRecordText = 'Press recording';
  Timer? voiceRecordTimer;
  int timerSecond = 0;
  PlatformSoundRecorder soundRecorder =
      PlatformSoundRecorder(codec: Codec.pcm16WAV);
  RecorderController recorderController = RecorderController();
  JustAudioRecorderController justAudioRecorder = JustAudioRecorderController();

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  ///录音和停止录音的切换，采用flutter_sound组件
  _switchVoiceRecording() async {
    voiceRecording = !voiceRecording;
    if (voiceRecording) {
      //开始录音
      timerSecond = 0;
      //开始计时
      voiceRecordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        var timerDuration = Duration(seconds: timerSecond++);
        voiceRecordText =
            '${timerDuration.inHours}:${timerDuration.inMinutes}:${timerDuration.inSeconds}';
        setState(() {});
      });
      //开始录音
      await soundRecorder.init();
      final dir = await getTemporaryDirectory();
      String filename = '${dir.path}/1.wav';
      await soundRecorder.startRecorder(filename: filename);
    } else {
      //停止计时和录音
      if (voiceRecordTimer != null) {
        voiceRecordTimer!.cancel();
        voiceRecordTimer = null;
        voiceRecordText = 'Press recording';
        timerSecond = 0;
        await soundRecorder.stopRecorder();
        setState(() {});
      }
    }
  }

  AudioWaveforms _buildAudioWaveforms(BuildContext context) {
    AudioWaveforms audioWaveforms = AudioWaveformsUtil.buildAudioWaveforms(
        size: const Size(0, 0), recorderController: recorderController);

    return audioWaveforms;
  }

  ///录音和停止录音的切换，采用AudioWaveforms组件
  _switchAudioWaveforms() async {
    voiceRecording = !voiceRecording;
    if (voiceRecording) {
      //开始录音
      timerSecond = 0;
      //开始计时
      voiceRecordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        var timerDuration = Duration(seconds: timerSecond++);
        voiceRecordText =
            '${timerDuration.inHours}:${timerDuration.inMinutes}:${timerDuration.inSeconds}';
        setState(() {});
      });
      //开始录音
      final dir = await getTemporaryDirectory();
      String filename = '${dir.path}/1.wav';
      await recorderController.record(filename);
    } else {
      //停止计时和录音
      if (voiceRecordTimer != null) {
        voiceRecordTimer!.cancel();
        voiceRecordTimer = null;
        voiceRecordText = 'Press recording';
        timerSecond = 0;
        String? filename = await recorderController.stop();
        if (filename != null) {
          Uint8List data = await FileUtil.readFile(filename);

          ///后面可以生成消息并发送
        }
        setState(() {});
      }
    }
  }

  ///录音和停止录音的切换，采用Record组件
  _switchAudioRecord() async {
    voiceRecording = !voiceRecording;
    if (voiceRecording) {
      //开始录音
      timerSecond = 0;
      //开始计时
      voiceRecordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        var timerDuration = Duration(seconds: timerSecond++);
        voiceRecordText =
            '${timerDuration.inHours}:${timerDuration.inMinutes}:${timerDuration.inSeconds}';
        setState(() {});
      });
      //开始录音
      final dir = await getTemporaryDirectory();
      String filename = '${dir.path}/1.mp3';
      await justAudioRecorder.start(path: filename);
    } else {
      //停止计时和录音
      if (voiceRecordTimer != null) {
        voiceRecordTimer!.cancel();
        voiceRecordTimer = null;
        voiceRecordText = 'Press recording';
        timerSecond = 0;
        String? filename = await justAudioRecorder.stop();
        if (filename != null) {
          Uint8List data = await FileUtil.readFile(filename);

          ///后面可以生成消息并发送
        }
        setState(() {});
      }
    }
  }

  AudioFileWaveforms _buildAudioFileWaveforms(BuildContext context) {
    PlayerController playerController = PlayerController();
    AudioFileWaveforms audioFileWaveforms =
        AudioWaveformsUtil.buildAudioFileWaveforms(
            size: const Size(0, 0), playerController: playerController);

    return audioFileWaveforms;
  }

  Widget _buildVoiceRecordButton(context) {
    return TextButton(
      style: WidgetUtil.buildButtonStyle(),
      child: Text(AppLocalizations.t(voiceRecordText)),
      onPressed: () async {
        await _switchAudioWaveforms();
      },
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
                  ? const Icon(Icons.record_voice_over)
                  : const Icon(Icons.keyboard),
              onTap: () {
                setState(() {
                  voiceVisible = !voiceVisible;
                });
              },
            ),
          ),
          Expanded(
              child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: iconInset, vertical: iconInset),
                  child: voiceVisible
                      ? _buildExtendedTextField(context)
                      : _buildVoiceRecordButton(context))),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: InkWell(
              child: const Icon(Icons.emoji_emotions),
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
                  child: const Icon(Icons.add_circle),
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
                  child: const Icon(Icons.send),
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

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_update);
    super.dispose();
  }
}
