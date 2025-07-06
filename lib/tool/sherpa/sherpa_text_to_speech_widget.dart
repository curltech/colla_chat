import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/platform_text_to_speech_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/sherpa/sherpa_config_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Sherpa的离线TTS配置和安装界面
class SherpaTextToSpeechWidget extends StatelessWidget {
  final AudioPlayer player = AudioPlayer();
  late Stream<PlayerState> playerStateStream = player.onPlayerStateChanged;
  String? filename;
  String? text;
  bool isInitialized = false;
  final ValueNotifier<int> _maxSpeakerId = ValueNotifier<int>(0);
  final ValueNotifier<double> speed = ValueNotifier<double>(1.0);
  ValueNotifier<TtsState> ttsState = ValueNotifier<TtsState>(TtsState.stopped);
  ValueNotifier<bool> sherpaPresent = ValueNotifier<bool>(false);

  OfflineTts? offlineTts;

  Future<bool> checkSherpa() async {
    sherpaPresent.value = await SherpaConfigUtil.initializeSherpaModel();

    return sherpaPresent.value;
  }

  SherpaTextToSpeechWidget({super.key}) {
    playerStateStream.listen((PlayerState playerState) {
      if (playerState == PlayerState.stopped ||
          playerState == PlayerState.completed) {
        ttsState.value = TtsState.stopped;
      } else if (playerState == PlayerState.playing) {
        ttsState.value = TtsState.playing;
      } else if (playerState == PlayerState.paused) {
        ttsState.value = TtsState.paused;
      }
    });
  }

  Future<void> init() async {
    if (!isInitialized) {
      await checkSherpa();
      initBindings();
      offlineTts?.free();
      if (sherpaPresent.value) {
        offlineTts = await SherpaConfigUtil.createOfflineTts();
        isInitialized = true;
        logger.i('create offlineTts successfully');
      }
    }
  }

  /// 速度
  Widget _buildSpeedWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AutoSizeText(AppLocalizations.t('Speed')),
      const SizedBox(
        height: 5.0,
      ),
      ValueListenableBuilder(
          valueListenable: speed,
          builder: (BuildContext context, speed, Widget? child) {
            return Slider(
              label:
                  "${AppLocalizations.t("Speech speed")} ${speed.toStringAsPrecision(2)}",
              min: 0.5,
              max: 3.0,
              divisions: 25,
              value: speed,
              onChanged: (value) {
                this.speed.value = value;
              },
              activeColor: myself.primary,
              inactiveColor: Colors.grey,
              secondaryActiveColor: Colors.yellow,
              thumbColor: myself.primary,
            );
          })
    ]);
  }

  generate() async {
    await player.stop();
    _maxSpeakerId.value = offlineTts?.numSpeakers ?? 0;
    if (_maxSpeakerId.value > 0) {
      _maxSpeakerId.value -= 1;
    }

    if (offlineTts == null) {
      logger.e('Failed to initialize tts');
      return;
    }

    const int sid = 0;

    final stopwatch = Stopwatch();
    stopwatch.start();
    final GeneratedAudio audio =
        offlineTts!.generate(text: text!, sid: sid, speed: speed.value);
    filename = await FileUtil.getTempFilename(extension: 'wav');

    final ok = writeWave(
      filename: filename!,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    if (!ok) {
      logger.e('Failed to save generated audio');
    }
    stopwatch.stop();
    double elapsed = stopwatch.elapsed.inMilliseconds.toDouble();

    double waveDuration =
        audio.samples.length.toDouble() / audio.sampleRate.toDouble();

    logger.i(
      'Saved to\n$filename!\n'
      'Elapsed: ${(elapsed / 1000).toStringAsPrecision(4)} s\n'
      'Wave duration: ${waveDuration.toStringAsPrecision(4)} s\n'
      'RTF: ${(elapsed / 1000).toStringAsPrecision(4)}/${waveDuration.toStringAsPrecision(4)} '
      '= ${(elapsed / 1000 / waveDuration).toStringAsPrecision(3)} ',
    );
  }

  speak(String text) async {
    if (this.text != text) {
      this.text = text;
      await generate();
    }
    await player.stop();
    if (filename != null) {
      await player.play(DeviceFileSource(filename!));
    }
  }

  pause() async {
    await player.pause();
  }

  stop() async {
    await player.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ValueListenableBuilder(
        valueListenable: sherpaPresent,
        builder: (BuildContext context, value, Widget? child) {
          if (value) {
            return Column(
              children: <Widget>[
                _buildSpeedWidget(),
              ],
            );
          }
          return Center(
            child: Text(AppLocalizations.t('Sherpa is not uninstalled')),
          );
        },
      ),
    );
  }

  void dispose() {
    player.dispose();
    offlineTts?.free();
    text = null;
    if (filename != null) {
      File(filename!).delete();
    }
  }
}
