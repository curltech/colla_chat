import 'dart:io';
import 'dart:typed_data';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/core/enums/editor_mode.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

/// 图像编辑界面
class ImageEditorWidget extends StatelessWidget with TileDataMixin {
  ImageEditorWidget({
    super.key,
  });

  @override
  String get routeName => 'image_editor';

  @override
  IconData get iconData => Icons.image_outlined;

  @override
  String get title => 'ImageEditor';

  @override
  bool get withLeading => true;

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );
  final ValueNotifier<int> index = ValueNotifier<int>(0);
  final SwiperController swiperController = SwiperController();

  Widget _buildImageEditor(BuildContext context) {
    Widget mediaView = Swiper(
      itemCount: 2,
      index: index.value,
      controller: swiperController,
      onIndexChanged: (int index) {
        this.index.value = index;
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return playlistWidget;
        }
        if (index == 1) {
          return Obx(
            () {
              String? filename = playlistController.current?.filename;
              if (filename == null) {
                return nilBox;
              }
              return ProImageEditor.file(File(filename),
                  callbacks: ProImageEditorCallbacks(
                    onImageEditingComplete: (Uint8List bytes) async {
                      String? name = await DialogUtil.showTextFormField(
                          title: 'Save as', content: 'Filename', tip: filename);
                      if (name != null) {
                        await FileUtil.writeFileAsBytes(bytes, name);
                        DialogUtil.info(
                            content: 'Save file:$name successfully');
                      }
                    },
                    onCloseEditor: (EditorMode mode) {
                      indexWidgetProvider.pop(context: context);
                    },
                  ));
            },
          );
        }
        return nilBox;
      },
    );

    return Center(
      child: mediaView,
    );
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Image editor'),
                onPressed: () async {
                  await swiperController.move(1);
                },
                icon: const Icon(Icons.task_alt_outlined),
              ),
              IconButton(
                tooltip: AppLocalizations.t('More'),
                onPressed: () {
                  playlistWidget.showActionCard(context);
                },
                icon: const Icon(Icons.more_horiz_outlined),
              ),
            ]);
          } else {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () async {
                  await swiperController.move(0);
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              ),
            ]);
          }
        });
    children.add(btn);

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      child: _buildImageEditor(context),
    );
  }
}
