import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/entity/poem/poem.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/poem/poem_content_widget.dart';
import 'package:colla_chat/plugin/platform_text_to_speech_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/poem/poem.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/adaptive_container.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class PoemWidget extends StatelessWidget with TileDataMixin {
  final DataListController<Poem> poemController = DataListController<Poem>();
  late final PoemContentWidget poemContentWidget = PoemContentWidget(
    poemController: poemController,
  );

  PoemWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'poem';

  @override
  IconData get iconData => Icons.library_music_outlined;

  @override
  String get title => 'Poem';

  String? get information => 'Search over 800k chinese poems';

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
  late final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(searchDataField);

  final ExpansibleController expansibleController = ExpansibleController();

  Widget _buildPlatformReactiveForm(BuildContext context) {
    var platformReactiveForm = PlatformReactiveForm(
      height: 350,
      spacing: 5.0,
      submitLabel: 'Search',
      platformReactiveFormController: platformReactiveFormController,
      onSubmit: (Map<String, dynamic> values) {
        poemController.clear();
        _onSubmit(context, values);
      },
    );
    Widget expansionTile = ExpansionTile(
      controller: expansibleController,
      childrenPadding: const EdgeInsets.all(0),
      maintainState: true,
      title: Text(
        AppLocalizations.t('Search condition'),
      ),
      initiallyExpanded: true,
      children: [platformReactiveForm],
    );

    return expansionTile;
  }

  _onSubmit(BuildContext context, Map<String, dynamic> values,
      {int from = 0, int limit = 10}) async {
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
      DialogUtil.error(content: 'Please input search key');
      return;
    }
    try {
      expansibleController.collapse();
    } catch (e) {
      logger.e('collapse failure:$e');
    }
    List<Poem> poems = [];
    DialogUtil.loadingShow();
    try {
      poems = await poemService.sendSearchPoem(
          title: title,
          author: author,
          rhythmic: rhythmic,
          paragraphs: paragraphs,
          from: from,
          limit: limit);
    } catch (e) {
      logger.e('sendSearchPoem failure:$e');
    }
    DialogUtil.loadingHide();
    poemController.addAll(poems);
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

  final PlatformTextToSpeechWidget platformTextToSpeechWidget =
      PlatformTextToSpeechWidget();

  final RxBool platformTextToSpeech = true.obs;

  Future<void> _onRefresh(BuildContext context) async {
    int length = poemController.data.length;
    Map<String, dynamic> values = platformReactiveFormController.values;
    _onSubmit(context, values, from: length);
  }

  Widget _buildPoemListWidget(BuildContext context) {
    return Column(children: [
      const SizedBox(
        height: 5,
      ),
      _buildPlatformReactiveForm(context),
      Expanded(child: Obx(
        () {
          List<TileData> tiles = [];
          RxList<Poem> poems = poemController.data;
          if (poems.isNotEmpty) {
            int i = 0;
            for (var poem in poems) {
              tiles.add(TileData(
                title: poem.title,
                subtitle: poem.rhythmic,
                selected: poemController.currentIndex.value == i,
                titleTail: '${poem.dynasty} ${poem.author}',
                onTap: (int index, String title, {String? subtitle}) {
                  poemController.setCurrentIndex = index;
                },
              ));
              i++;
            }
            return DataListView(
              itemCount: tiles.length,
              itemBuilder: (BuildContext context, int index) {
                return tiles[index];
              },
              onScrollMax: () async {
                return await _onRefresh(context);
              },
              onRefresh: () async {
                return await _onRefresh(context);
              },
            );
          }
          return Center(child: AutoSizeText(AppLocalizations.t('No poem')));
        },
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
        builder:
            (context, appDataProvider, indexWidgetProvider, myself, child) {
      ContainerType containerType = ContainerType.swiper;
      if (appDataProvider.landscape) {
        if (appDataProvider.bodyWidth == 0) {
          containerType = ContainerType.resizeable;
        }
      }
      var poemWidget = AppBarView(
          title: title,
          withLeading: true,
          child: AdaptiveContainer(
              pixels: 380,
              containerType: containerType,
              main: _buildPoemListWidget(context),
              body: poemContentWidget));

      return poemWidget;
    });
    return provider;
  }
}
