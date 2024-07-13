import 'dart:io';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/poem/poem.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/plugin/text_to_speech_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/poem/poem.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class PoemWidget extends StatelessWidget with TileDataMixin {
  PoemWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'poem';

  @override
  IconData get iconData => Icons.library_music_outlined;

  @override
  String get title => 'Poem';

  final List<PlatformDataField> searchDataField = [
    PlatformDataField(
        name: 'title',
        label: 'Title',
        prefixIcon: Icon(
          Icons.title,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'author',
        label: 'Author',
        prefixIcon: Icon(
          Icons.edit,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'rhythmic',
        label: 'Rhythmic',
        prefixIcon: Icon(
          Icons.audio_file_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'dynasty',
        label: 'Dynasty',
        prefixIcon: Icon(
          Icons.date_range,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'paragraphs',
        label: 'Paragraphs',
        prefixIcon: Icon(
          Icons.content_copy_outlined,
          color: myself.primary,
        )),
  ];
  late final FormInputController formInputController =
      FormInputController(searchDataField);

  DataListController<Poem> poemController = DataListController<Poem>();

  ValueNotifier<Poem?> poem = ValueNotifier<Poem?>(null);

  ExpansionTileController expansionTileController = ExpansionTileController();

  bool isExpanded() {
    try {
      return expansionTileController.isExpanded;
    } catch (e) {
      logger.e('expansionTileController.isExpanded failure:$e');
    }
    return false;
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: 280,
          spacing: 5.0,
          okLabel: 'Search',
          controller: formInputController,
          onOk: (Map<String, dynamic> values) {
            _onOk(context, values);
          },
        ));
    Widget expansionTile = ExpansionTile(
      controller: expansionTileController,
      childrenPadding: const EdgeInsets.all(0),
      maintainState: true,
      title: CommonAutoSizeText(
        AppLocalizations.t('Search condition'),
      ),
      initiallyExpanded: isExpanded(),
      children: [formInputWidget],
    );

    return expansionTile;
  }

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    String? title = values['title'];
    String? author = values['author'];
    String? rhythmic = values['rhythmic'];
    String? dynasty = values['dynasty'];
    String? paragraphs = values['paragraphs'];
    if (StringUtil.isEmpty(title) &&
        StringUtil.isEmpty(author) &&
        StringUtil.isEmpty(rhythmic) &&
        StringUtil.isEmpty(dynasty) &&
        StringUtil.isEmpty(paragraphs)) {
      DialogUtil.error(context, content: 'Please input search key');
      return;
    }
    try {
      expansionTileController.collapse();
    } catch (e) {
      logger.e('collapse failure:$e');
    }
    List<Poem> poems = [];
    DialogUtil.loadingShow(context);
    try {
      poems = await poemService.sendSearchPoem(
          title: title,
          author: author,
          rhythmic: rhythmic,
          paragraphs: paragraphs,
          from: 0,
          limit: 100);
    } catch (e) {
      logger.e('sendSearchPoem failure:$e');
    }
    DialogUtil.loadingHide(context);
    poemController.replaceAll(poems);
  }

  Future<List<TileData>> _buildJsonFiles(String path) async {
    List<TileData> tiles = [];
    Directory directory = Directory(path);
    if (!directory.existsSync()) {
      return [];
    }
    List<FileSystemEntity> entries = directory.listSync();
    for (var entry in entries) {
      FileStat stat = entry.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        Directory dir = Directory(entry.path);
        String collection = p.basename(entry.path);
        List<FileSystemEntity> fileEntries = dir.listSync();
        for (var fileEntry in fileEntries) {
          FileStat fileStat = fileEntry.statSync();
          if (fileStat.type == FileSystemEntityType.file) {
            String filename = fileEntry.path;
            if (filename.endsWith('json')) {
              tiles.add(TileData(
                  title: FileUtil.filename(filename), subtitle: collection));
            }
          }
        }
      }
    }

    return tiles;
  }

  SwiperController swiperController = SwiperController();

  int index = 0;

  TextToSpeechWidget textToSpeechWidget = TextToSpeechWidget();

  Widget _buildPoemListWidget(BuildContext context) {
    return Column(children: [
      const SizedBox(
        height: 5,
      ),
      _buildFormInputWidget(context),
      Expanded(
          child: ListenableBuilder(
        listenable: poemController,
        builder: (BuildContext context, Widget? child) {
          List<TileData> tiles = [];
          List<Poem> poems = poemController.data;
          if (poems.isNotEmpty) {
            int i = 0;
            for (var poem in poems) {
              tiles.add(TileData(
                title: poem.title,
                subtitle: poem.rhythmic,
                selected: poemController.currentIndex == i,
                titleTail: '${poem.dynasty} ${poem.author}',
                onTap: (int index, String title, {String? subtitle}) {
                  poemController.currentIndex = index;
                  this.poem.value = poemController.current;
                  swiperController.move(1);
                },
              ));
              i++;
            }
            return DataListView(
              itemCount: tiles.length,
              itemBuilder: (BuildContext context, int index) {
                return tiles[index];
              },
            );
          }
          return Center(
              child: CommonAutoSizeText(AppLocalizations.t('No poem')));
        },
      )),
    ]);
  }

  Widget _buildPoemContent(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: poem,
      builder: (BuildContext context, poem, Widget? child) {
        if (poem != null && poem.paragraphs != null) {
          List<String> titles = poem.title.split('。');
          List<Widget> titleWidgets = [];
          int i = 0;
          for (var title in titles) {
            if (i == 0) {
              titleWidgets.add(CommonAutoSizeText(
                title,
                style: const TextStyle(fontSize: 28),
              ));
            } else {
              titleWidgets.add(CommonAutoSizeText(
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
            paragraphWidgets.add(CommonAutoSizeText(
              paragraph,
              style: const TextStyle(fontSize: 16),
            ));
          }
          return Column(
            children: [
              ButtonBar(
                alignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                      color: Colors.white,
                      hoverColor: myself.primary,
                      onPressed: () {
                        swiperController.move(0);
                      },
                      icon: const Icon(Icons.keyboard_arrow_left)),
                  ValueListenableBuilder(
                    valueListenable: textToSpeechWidget.ttsState,
                    builder: (BuildContext context, ttsState, Widget? child) {
                      return IconButton(
                          color: Colors.white,
                          hoverColor: myself.primary,
                          onPressed: () {
                            if (ttsState == TtsState.stopped) {
                              textToSpeechWidget.speak(poem.paragraphs!);
                            }
                            if (ttsState == TtsState.paused) {
                              textToSpeechWidget.speak(poem.paragraphs!);
                            }
                            if (ttsState == TtsState.playing) {
                              textToSpeechWidget.pause();
                            }
                          },
                          icon: ttsState == TtsState.stopped ||
                                  ttsState == TtsState.paused
                              ? const Icon(Icons.play_arrow)
                              : const Icon(Icons.pause));
                    },
                  ),
                  IconButton(
                      color: Colors.white,
                      hoverColor: myself.primary,
                      onPressed: () {
                        textToSpeechWidget.stop();
                      },
                      icon: const Icon(Icons.stop)),
                ],
              ),
              Expanded(
                  child: Column(
                children: [
                  ...titleWidgets,
                  const SizedBox(
                    height: 15,
                  ),
                  CommonAutoSizeText('${poem.dynasty} ${poem.author}'),
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
        return Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var poemWidget = AppBarView(
      title: title,
      withLeading: withLeading,
      child: Swiper(
        itemCount: 2,
        controller: swiperController,
        onIndexChanged: (index) {
          this.index = index;
        },
        index: index,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _buildPoemListWidget(context);
          }
          if (index == 1) {
            return _buildPoemContent(context);
          }

          return Container();
        },
      ),
    );

    return poemWidget;
  }
}
