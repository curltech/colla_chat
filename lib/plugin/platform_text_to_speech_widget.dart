import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class PlatformTextToSpeechWidget extends StatelessWidget {
  late FlutterTts flutterTts;
  ValueNotifier<String?> language = ValueNotifier<String?>(null);
  ValueNotifier<String?> engine = ValueNotifier<String?>(null);
  ValueNotifier<double> volume = ValueNotifier<double>(0.5);
  ValueNotifier<double> pitch = ValueNotifier<double>(1.0);
  ValueNotifier<double> rate = ValueNotifier<double>(0.2);
  bool isCurrentLanguageInstalled = false;

  ValueNotifier<TtsState> ttsState = ValueNotifier<TtsState>(TtsState.stopped);

  PlatformTextToSpeechWidget({super.key}) {
    initTts();
  }

  dynamic initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions(true);

    if (platformParams.android) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    if (platformParams.ios) {
      flutterTts.setSharedInstance(true);
      flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt);
    }

    flutterTts.setStartHandler(() {
      ttsState.value = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      ttsState.value = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      ttsState.value = TtsState.stopped;
    });

    flutterTts.setPauseHandler(() {
      ttsState.value = TtsState.paused;
    });

    flutterTts.setContinueHandler(() {
      ttsState.value = TtsState.continued;
    });

    flutterTts.setErrorHandler((msg) {
      ttsState.value = TtsState.stopped;
    });
  }

  /// 获取所有的语言
  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  /// 获取所有的引擎
  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  /// 获取缺省引擎
  Future<dynamic> _getDefaultEngine() async {
    return await flutterTts.getDefaultEngine;
  }

  /// 获取缺省的语音
  Future<dynamic> _getDefaultVoice() async {
    return await flutterTts.getDefaultVoice;
  }

  Future<int?> getMaxSpeechInputLength() async {
    return await flutterTts.getMaxSpeechInputLength;
  }

  /// 设置等待选项
  Future<void> _setAwaitOptions(bool wait) async {
    await flutterTts.awaitSpeakCompletion(wait);
  }

  Future<void> _setAwaitSynthCompletion(bool wait) async {
    await flutterTts.awaitSynthCompletion(wait);
  }

  Future<void> _synthesizeToFile(String text, String filename) async {
    await flutterTts.synthesizeToFile(
        text, platformParams.android ? "$filename.wav" : "$filename.caf");
  }

  /// 播放
  Future<void> speak(String text) async {
    await flutterTts.setVolume(volume.value);
    await flutterTts.setSpeechRate(rate.value);
    await flutterTts.setPitch(pitch.value);

    await flutterTts.speak(text);
  }

  /// 停止
  Future<void> stop() async {
    var result = await flutterTts.stop();
    if (result == 1) ttsState.value = TtsState.stopped;
  }

  ///暂停
  Future<void> pause() async {
    var result = await flutterTts.pause();
    if (result == 1) ttsState.value = TtsState.paused;
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changeEngine(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language.value = null;
    engine.value = selectedEngine;
  }

  List<DropdownMenuItem<String>> getLanguageOptions(List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?,
          child: Row(children: [
            const SizedBox(
              width: 50,
            ),
            Text((type as String)),
            const SizedBox(
              width: 50,
            ),
          ])));
    }
    return items;
  }

  void changeLanguage(String? language) {
    this.language.value = language;
    flutterTts.setLanguage(this.language.value!);
    if (platformParams.android) {
      flutterTts
          .isLanguageInstalled(this.language.value!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));
    }
  }

  Widget _buildEngineOptionWidget() {
    if (platformParams.android) {
      return FutureBuilder<dynamic>(
          future: _getEngines(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return _enginesDropDownSection(snapshot.data as List<dynamic>);
            } else if (snapshot.hasError) {
              return AutoSizeText(
                  AppLocalizations.t('Error loading engines...'));
            } else {
              return AutoSizeText(
                  AppLocalizations.t('Loading engines...'));
            }
          });
    } else {
      return const SizedBox(width: 0, height: 0);
    }
  }

  Widget _buildLanguageOptionWidget() {
    return Column(children: [
      FutureBuilder<dynamic>(
          future: _getLanguages(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return _buildLanguageOption(snapshot.data as List<dynamic>);
            } else if (snapshot.hasError) {
              return AutoSizeText(
                  AppLocalizations.t('Error loading languages...'));
            } else {
              return AutoSizeText(
                  AppLocalizations.t('Loading Languages...'));
            }
          }),
    ]);
  }

  Widget _enginesDropDownSection(List<dynamic> engines) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      child: DropdownButton(
          value: engine,
          items: getEnginesDropDownMenuItems(engines),
          onChanged: (Object? item) {
            changeEngine(item?.toString());
          }),
    );
  }

  /// 选择语言
  Widget _buildLanguageOption(List<dynamic> languages) {
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      AutoSizeText(AppLocalizations.t('Language')),
      const SizedBox(
        width: 15.0,
      ),
      ValueListenableBuilder(
        valueListenable: language,
        builder: (BuildContext context, language, Widget? child) {
          return DropdownButton(
              value: language,
              items: getLanguageOptions(languages),
              onChanged: (Object? item) {
                changeLanguage(item?.toString());
              });
        },
      ),
      Visibility(
        visible: platformParams.android,
        child: AutoSizeText(
            "${AppLocalizations.t("Is installed")}: $isCurrentLanguageInstalled"),
      ),
    ]);
  }

  /// 音量
  Widget _buildVolumeWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(AppLocalizations.t('Volume')),
        const SizedBox(
          height: 5.0,
        ),
        ValueListenableBuilder(
          valueListenable: volume,
          builder: (BuildContext context, volume, Widget? child) {
            return Slider(
              value: volume,
              onChanged: (newVolume) {
                this.volume.value = newVolume;
              },
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: "${AppLocalizations.t("Volume")}: $volume",
              activeColor: myself.primary,
              inactiveColor: Colors.grey,
              secondaryActiveColor: Colors.yellow,
              thumbColor: myself.primary,
            );
          },
        ),
      ],
    );
  }

  /// 音高
  Widget _buildPitchWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AutoSizeText(AppLocalizations.t('Pitch')),
      const SizedBox(
        height: 5.0,
      ),
      ValueListenableBuilder(
          valueListenable: pitch,
          builder: (BuildContext context, pitch, Widget? child) {
            return Slider(
              value: pitch,
              onChanged: (newPitch) {
                this.pitch.value = newPitch;
              },
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: "${AppLocalizations.t("Pitch")}: $pitch",
              activeColor: myself.primary,
              inactiveColor: Colors.grey,
              secondaryActiveColor: Colors.yellow,
              thumbColor: myself.primary,
            );
          }),
    ]);
  }

  /// 速度
  Widget _buildRateWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AutoSizeText(AppLocalizations.t('Rate')),
      const SizedBox(
        height: 5.0,
      ),
      ValueListenableBuilder(
          valueListenable: rate,
          builder: (BuildContext context, rate, Widget? child) {
            return Slider(
              value: rate,
              onChanged: (newRate) {
                this.rate.value = newRate;
              },
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: "${AppLocalizations.t("Rate")}: $rate",
              activeColor: myself.primary,
              inactiveColor: Colors.grey,
              secondaryActiveColor: Colors.yellow,
              thumbColor: myself.primary,
            );
          }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const SizedBox(
              height: 5.0,
            ),
            _buildEngineOptionWidget(),
            const SizedBox(
              height: 5.0,
            ),
            _buildLanguageOptionWidget(),
            const SizedBox(
              height: 10.0,
            ),
            Column(
              children: [
                _buildVolumeWidget(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildPitchWidget(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildRateWidget()
              ],
            ),
          ],
        ));
  }

  void dispose() {
    flutterTts.stop();
  }
}
