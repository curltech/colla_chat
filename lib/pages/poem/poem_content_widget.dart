import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/poem/poem.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/poem/poem_widget.dart';
import 'package:colla_chat/plugin/platform_text_to_speech_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/sherpa/sherpa_text_to_speech_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PoemContentWidget extends StatelessWidget with TileDataMixin {
  PoemContentWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'poem_content';

  @override
  IconData get iconData => Icons.library_music_outlined;

  @override
  String get title => 'Poem content';



  PlatformTextToSpeechWidget platformTextToSpeechWidget =
      PlatformTextToSpeechWidget();

  SherpaTextToSpeechWidget sherpaTextToSpeechWidget =
      SherpaTextToSpeechWidget();

  RxBool platformTextToSpeech = true.obs;

  speak(Poem poem) async {
    var platformTextToSpeech = this.platformTextToSpeech.value;
    if (platformTextToSpeech) {
      var ttsState = platformTextToSpeechWidget.ttsState.value;

      if (ttsState == TtsState.stopped || ttsState == TtsState.paused) {
        platformTextToSpeechWidget.speak(poem.paragraphs!);
      }
    } else {
      await sherpaTextToSpeechWidget.init();
      var ttsState = sherpaTextToSpeechWidget.ttsState.value;

      if (ttsState == TtsState.stopped || ttsState == TtsState.paused) {
        sherpaTextToSpeechWidget.speak(poem.paragraphs!);
      }
    }
  }

  pause() {
    var platformTextToSpeech = this.platformTextToSpeech.value;
    if (platformTextToSpeech) {
      var ttsState = platformTextToSpeechWidget.ttsState.value;
      if (ttsState == TtsState.playing) {
        platformTextToSpeechWidget.pause();
      }
    } else {
      var ttsState = sherpaTextToSpeechWidget.ttsState.value;
      if (ttsState == TtsState.playing) {
        sherpaTextToSpeechWidget.pause();
      }
    }
  }

  stop() {
    var platformTextToSpeech = this.platformTextToSpeech.value;
    if (platformTextToSpeech) {
      platformTextToSpeechWidget.stop();
    } else {
      sherpaTextToSpeechWidget.stop();
    }
  }

  Widget _buildPoemContent(BuildContext context) {
    return Obx(
      () {
        Poem? poem = poemController.current;
        if (poem != null && poem.paragraphs != null) {
          List<String> titles = poem.title.split('。');
          List<Widget> titleWidgets = [];
          int i = 0;
          for (var title in titles) {
            if (i == 0) {
              titleWidgets.add(AutoSizeText(
                title,
                style: const TextStyle(fontSize: 28),
              ));
            } else {
              titleWidgets.add(AutoSizeText(
                title,
                style: const TextStyle(fontSize: 12),
              ));
            }
            i++;
          }
          final reg = RegExp(r'[。|？|；|！|：]');
          List<String> paragraphs = poem.paragraphs!.split(reg);
          List<Widget> paragraphWidgets = [];
          for (var paragraph in paragraphs) {
            paragraphWidgets.add(AutoSizeText(
              paragraph,
              style: const TextStyle(fontSize: 16),
            ));
          }
          return Column(
            children: [
              OverflowBar(
                alignment: MainAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: platformTextToSpeechWidget.ttsState,
                    builder: (BuildContext context, ttsState, Widget? child) {
                      return IconButton(
                        color: Colors.white,
                        hoverColor: myself.primary,
                        onPressed: () {
                          if (ttsState == TtsState.stopped ||
                              ttsState == TtsState.paused) {
                            speak(poem);
                          }
                          if (ttsState == TtsState.playing) {
                            pause();
                          }
                        },
                        icon: ttsState == TtsState.stopped ||
                                ttsState == TtsState.paused
                            ? const Icon(Icons.play_arrow)
                            : const Icon(Icons.pause),
                        tooltip: ttsState == TtsState.stopped ||
                                ttsState == TtsState.paused
                            ? AppLocalizations.t('Play')
                            : AppLocalizations.t('Pause'),
                      );
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    hoverColor: myself.primary,
                    onPressed: () {
                      stop();
                    },
                    icon: const Icon(Icons.stop),
                    tooltip: AppLocalizations.t('Stop'),
                  ),
                  IconButton(
                    color: Colors.white,
                    hoverColor: myself.primary,
                    onPressed: () async {
                      await DialogUtil.show(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: platformTextToSpeechWidget,
                            );
                          });
                    },
                    icon: const Icon(Icons.settings),
                    tooltip: AppLocalizations.t('Setting'),
                  ),
                  ValueListenableBuilder(
                    valueListenable: platformTextToSpeech,
                    builder: (BuildContext context, value, Widget? child) {
                      return ToggleButtons(
                        borderWidth: 2.0,
                        fillColor: Colors.white,
                        selectedBorderColor: myself.primary,
                        selectedColor: myself.primary,
                        borderColor: Colors.grey,
                        borderRadius: borderRadius,
                        isSelected: value ? [true, false] : [false, true],
                        onPressed: (int newIndex) {
                          if (newIndex == 0) {
                            platformTextToSpeech.value = true;
                          } else if (newIndex == 1) {
                            platformTextToSpeech.value = false;
                          }
                        },
                        children: <Widget>[
                          Tooltip(
                              message: AppLocalizations.t('Platform'),
                              child: Icon(
                                Icons.record_voice_over_outlined,
                                color: value ? myself.primary : Colors.white,
                              )),
                          Tooltip(
                              message: AppLocalizations.t('Sherpa'),
                              child: Icon(
                                Icons.multitrack_audio,
                                color: value ? Colors.white : myself.primary,
                              )),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                  child: Column(
                children: [
                  ...titleWidgets,
                  const SizedBox(
                    height: 15,
                  ),
                  AutoSizeText('${poem.dynasty} ${poem.author}'),
                  const SizedBox(
                    height: 15,
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                          child: SizedBox(
                              width: appDataProvider.secondaryBodyWidth,
                              child: Column(
                                children: [
                                  ...paragraphWidgets,
                                ],
                              )))),
                ],
              )),
            ],
          );
        }
        return nilBox;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var poemContentWidget = AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      child: _buildPoemContent(context),
    );

    return poemContentWidget;
  }
}
