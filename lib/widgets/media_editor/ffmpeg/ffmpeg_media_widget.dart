import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_helper.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_install_widget.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_util.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/session_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 选择多个视频文件，使用ffmpeg对video进行处理的界面
class FFMpegMediaWidget extends StatelessWidget with TileDataMixin {
  FFMpegMediaWidget({
    super.key,
    required this.playlistController,
  }) {
    checkFFMpeg();
  }

  @override
  String get routeName => 'ffmpeg_media';

  @override
  IconData get iconData => Icons.video_camera_back_outlined;

  @override
  String get title => 'FFMpegMedia';

  @override
  bool get withLeading => true;

  final PlaylistController playlistController;
  final FileType fileType = FileType.custom;
  final ValueNotifier<bool> ffmpegPresent = ValueNotifier<bool>(false);
  final ValueNotifier<String?> output = ValueNotifier<String?>(null);
  final ValueNotifier<bool> gridMode = ValueNotifier<bool>(false);
  final ValueNotifier<List<TileData>> tileData =
      ValueNotifier<List<TileData>>([]);
  final Map<String, FFMpegHelperSession> ffmpegSessions = {};

  Future<bool> checkFFMpeg() async {
    ffmpegPresent.value = await FFMpegHelper.initialize();

    return ffmpegPresent.value;
  }

  _onSelectFile(BuildContext context, int index, String filename,
      {String? subtitle}) async {
    List<ActionData> filePopActionData = [];
    String? mimeType = FileUtil.mimeType(filename);
    if (mimeType != null) {
      if (mimeType.startsWith('video') || filename.endsWith('rmvb')) {
        for (var videoExtension in playlistController.videoExtensions) {
          if (videoExtension != mimeType) {
            filePopActionData.add(
              ActionData(
                  label: videoExtension,
                  tooltip: 'convert to $videoExtension',
                  icon: const Icon(Icons.change_circle_outlined)),
            );
          }
        }
      } else if (mimeType.startsWith('audio')) {
        for (var audioExtension in playlistController.audioExtensions) {
          if (audioExtension != mimeType) {
            filePopActionData.add(
              ActionData(
                  label: audioExtension,
                  tooltip: 'convert to $audioExtension',
                  icon: const Icon(Icons.change_circle_outlined)),
            );
          }
        }
      } else if (mimeType.startsWith('image')) {
        for (var imageExtension in playlistController.imageExtensions) {
          if (imageExtension != mimeType) {
            filePopActionData.add(
              ActionData(
                  label: imageExtension,
                  tooltip: 'convert to $imageExtension',
                  icon: const Icon(Icons.change_circle_outlined)),
            );
          }
        }
      }

      await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              elevation: 0.0,
              insetPadding: EdgeInsets.zero,
              child: DataActionCard(
                  onPressed: (int index, String label, {String? value}) {
                    Navigator.pop(context);
                    _onFilePopAction(context, index, label, value: value);
                  },
                  crossAxisCount: 4,
                  actions: filePopActionData,
                  height: 200,
                  width: appDataProvider.secondaryBodyWidth,
                  iconSize: 30));
        },
      );
    }
  }

  Future<String?> _onFilePopAction(
      BuildContext context, int index, String label,
      {String? value}) async {
    String? filename = playlistController.current?.filename;
    if (filename == null) {
      return null;
    }
    int pos = filename.lastIndexOf('.');
    String output = '${filename.substring(0, pos)}.$label';
    String command = FFMpegHelper.buildCommand(
      input: filename,
      output: output,
    );
    FFMpegHelperSession session = await FFMpegHelper.runAsync([command],
        completeCallback: (FFMpegHelperSession session) async {
      _buildTileData(context);
    });
    ffmpegSessions[filename] = session;
    _buildTileData(context);
    List<ReturnCode?> returnCode = await session.getReturnCode();
    bool? success = returnCode.firstOrNull?.isValueSuccess();
    if (success != null && success) {
      return output;
    }

    return null;
  }

  Future<void> _buildTileData(BuildContext context) async {
    List<PlatformMediaSource> mediaSources = playlistController.data.toList();
    List<TileData> tileData = [];
    for (var mediaSource in mediaSources) {
      String filename = mediaSource.filename;
      File file = File(filename);
      bool exist = file.existsSync();
      if (!exist) {
        continue;
      }
      var length = file.lengthSync();
      bool selected = false;
      String? current = playlistController.current?.filename;
      if (current != null) {
        if (current == filename) {
          selected = true;
        }
      }
      Widget? thumbnailWidget = mediaSource.thumbnailWidget;
      FFMpegHelperSession? session = ffmpegSessions[filename];
      Widget? suffix;
      if (session != null) {
        SessionState state = await session.getState();
        if (state == SessionState.running) {
          suffix = IconButton(
              onPressed: () {
                session.cancelSession();
              },
              icon: const Icon(
                Icons.run_circle_outlined,
                color: Colors.yellow,
              ));
        }
        if (state == SessionState.completed) {
          suffix = const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          );
        }
        if (state == SessionState.failed) {
          suffix = IconButton(
              onPressed: () {
                session.cancelSession();
              },
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ));
        }
      }
      TileData tile = TileData(
        prefix: thumbnailWidget,
        title: FileUtil.filename(filename),
        subtitle: '$length',
        selected: selected,
        suffix: suffix,
        onTap: (int index, String title, {String? subtitle}) {
          playlistController.setCurrentIndex = index;
          _buildTileData(context);
        },
        onLongPress: (int index, String title, {String? subtitle}) {
          playlistController.setCurrentIndex = index;
          _buildTileData(context);
          _onSelectFile(context, index, title, subtitle: subtitle);
        },
      );
      tileData.add(tile);
      tile.endSlideActions = [
        TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String title, {String? subtitle}) {
              String? mimeType = FileUtil.mimeType(filename);
              if (mimeType != null) {
                if (mimeType.startsWith('image')) {
                  indexWidgetProvider.push('image_editor');
                }
                if (mimeType.startsWith('video')) {
                  indexWidgetProvider.push('video_editor');
                }
              }
            })
      ];
    }

    this.tileData.value = tileData;
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    children.add(IconButton(
      tooltip: AppLocalizations.t('information'),
      onPressed: () async {
        String? current = playlistController.current?.filename;
        if (current != null) {
          MediaInformation? info =
              await FFMpegUtil.getMediaInformation(current);
          if (info != null) {
            output.value = info.getAllProperties()!.toString();
            show(context, 'information');
          }
        }
      },
      icon: const Icon(Icons.info_outline),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('formats'),
      onPressed: () async {
        output.value = await FFMpegUtil.formats();
        show(context, 'formats');
      },
      icon: const Icon(Icons.format_align_center_outlined),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('encoders'),
      onPressed: () async {
        output.value = await FFMpegUtil.encoders();
        show(context, 'encoders');
      },
      icon: const Icon(Icons.qr_code),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('decoders'),
      onPressed: () async {
        output.value = await FFMpegUtil.decoders();
        show(context, 'decoders');
      },
      icon: const Icon(Icons.qr_code_scanner),
    ));
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('help'),
        onPressed: () async {
          output.value = await FFMpegUtil.help();
          show(context, 'help');
        },
        icon: const Icon(Icons.help_outline),
      ),
    );

    return children;
  }

  show(BuildContext context, String title) {
    DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              child: Column(children: [
            AppBarWidget(
              title: CommonAutoSizeText(AppLocalizations.t(title)),
            ),
            Expanded(
                child: SingleChildScrollView(
                    child: Container(
                        padding: const EdgeInsets.all(15.0),
                        child: CommonAutoSizeText(output.value ?? '')))),
          ]));
        });
  }

  Future<void> _addMediaSource(
    BuildContext context, {
    bool directory = false,
  }) async {
    try {
      List<PlatformMediaSource> mediaSources =
          await playlistController.sourceFilePicker(directory: directory);
    } catch (e) {
      DialogUtil.error(content: 'add media file failure:$e');
    }
  }

  ///播放列表按钮
  Widget _buildConvertFilesButton(BuildContext context) {
    return Column(
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.start,
          children: [
            IconButton(
              color: myself.primary,
              icon: ValueListenableBuilder(
                valueListenable: gridMode,
                builder: (BuildContext context, value, Widget? child) {
                  return Icon(
                    gridMode.value ? Icons.list : Icons.grid_on,
                    color: Colors.white,
                  );
                },
              ),
              onPressed: () {
                gridMode.value = !gridMode.value;
              },
              tooltip: AppLocalizations.t('Toggle grid mode'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.featured_play_list_outlined,
                color: Colors.white,
              ),
              onPressed: () async {
                await _addMediaSource(context, directory: true);
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Add media directory'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.playlist_add,
                color: Colors.white,
              ),
              onPressed: () async {
                await _addMediaSource(context);
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Add media file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.bookmark_remove,
                color: Colors.white,
              ),
              onPressed: () async {
                ffmpegSessions.clear();
                await playlistController.clear();
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Remove all media file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.playlist_remove,
                color: Colors.white, //myself.primary,
              ),
              onPressed: () async {
                var currentIndex = playlistController.currentIndex.value;
                if (currentIndex != -1) {
                  ffmpegSessions.remove(playlistController.current!.filename);
                  playlistController.delete(index: currentIndex);
                  _buildTileData(context);
                }
              },
              tooltip: AppLocalizations.t('Remove media file'),
            ),
          ],
        ),
      ],
    );
  }

  Future<Widget> _buildThumbnailView(BuildContext context) async {
    return ValueListenableBuilder(
        valueListenable: tileData,
        builder:
            (BuildContext context, List<TileData> tileData, Widget? child) {
          if (tileData.isEmpty) {
            return Container(
                alignment: Alignment.center,
                child: CommonAutoSizeText(AppLocalizations.t('file is empty')));
          }
          int crossAxisCount = 3;
          List<Widget> thumbnails = [];
          for (var tile in tileData) {
            List<Widget> children = [];
            children.add(const Spacer());
            children.add(CommonAutoSizeText(
              tile.title,
              style: const TextStyle(fontSize: AppFontSize.minFontSize),
            ));
            if (tile.subtitle != null) {
              children.add(const SizedBox(
                height: 2.0,
              ));
              children.add(CommonAutoSizeText(
                tile.subtitle!,
                style: const TextStyle(fontSize: AppFontSize.minFontSize),
              ));
            }
            var thumbnail = Container(
                decoration: tile.selected ?? false
                    ? BoxDecoration(
                        border: Border.all(width: 2, color: myself.primary))
                    : null,
                padding: EdgeInsets.zero,
                child: Card(
                    elevation: 0.0,
                    margin: EdgeInsets.zero,
                    shape: const ContinuousRectangleBorder(),
                    child: Stack(
                      children: [
                        tile.prefix ?? nilBox,
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children)
                      ],
                    )));
            thumbnails.add(thumbnail);
          }
          return ValueListenableBuilder(
            valueListenable: gridMode,
            builder: (BuildContext context, gridMode, Widget? child) {
              if (gridMode) {
                return GridView.builder(
                    itemCount: tileData.length,
                    //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        //横轴元素个数
                        crossAxisCount: crossAxisCount,
                        //纵轴间距
                        mainAxisSpacing: 4.0,
                        //横轴间距
                        crossAxisSpacing: 4.0,
                        //子组件宽高长度比例
                        childAspectRatio: 1),
                    itemBuilder: (BuildContext context, int index) {
                      //Widget Function(BuildContext context, int index)
                      return InkWell(
                          child: thumbnails[index],
                          onTap: () {
                            playlistController.setCurrentIndex = index;
                            var title = tileData[index].title;
                            var fn = tileData[index].onTap;
                            if (fn != null) {
                              fn(index, title);
                            }
                          },
                          onLongPress: () {
                            playlistController.setCurrentIndex = index;
                            var title = tileData[index].title;
                            var fn = tileData[index].onLongPress;
                            if (fn != null) {
                              fn(index, title);
                            }
                          });
                    });
              } else {
                return DataListView(
                  onTap: (int index, String title,
                      {TileData? group, String? subtitle}) {
                    playlistController.setCurrentIndex = index;
                  },
                  itemCount: tileData.length,
                  itemBuilder: (BuildContext context, int index) {
                    return tileData[index];
                  },
                );
              }
            },
          );
        });
  }

  Widget _buildConvertFilesWidget(BuildContext context) {
    return Column(children: [
      _buildConvertFilesButton(context),
      Expanded(
          child: PlatformFutureBuilder(
              future: _buildThumbnailView(context),
              builder: (BuildContext context, Widget fileWidget) {
                return fileWidget;
              })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _buildTileData(context);
    List<Widget>? rightWidgets = _buildRightWidgets(context);

    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: ValueListenableBuilder(
        valueListenable: ffmpegPresent,
        builder: (BuildContext context, value, Widget? child) {
          if (value) {
            return _buildConvertFilesWidget(context);
          }
          return FFMpegInstallWidget(
            onDownloadComplete: () {
              checkFFMpeg();
            },
          );
        },
      ),
    );
  }
}
