import 'dart:io';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_helper.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_install_widget.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_util.dart';
import 'package:ffmpeg_kit_flutter_new/media_information.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session_state.dart';
import 'package:flutter/material.dart';

/// 选择多个视频文件，使用ffmpeg对video进行处理的界面
class FFMpegMediaWidget extends StatelessWidget with TileDataMixin {
  FFMpegMediaWidget({
    super.key,
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

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );
  final ValueNotifier<bool> ffmpegPresent = ValueNotifier<bool>(false);
  final ValueNotifier<String?> output = ValueNotifier<String?>(null);
  final Map<String, FFMpegHelperSession> ffmpegSessions = {};
  final ValueNotifier<int> index = ValueNotifier<int>(0);
  final SwiperController swiperController = SwiperController();

  Future<bool> checkFFMpeg() async {
    ffmpegPresent.value = await FFMpegHelper.initialize();

    return ffmpegPresent.value;
  }

  _showTransferFileMenu(BuildContext context, String filename) async {
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
                  icon: const Icon(Icons.change_circle_outlined),
                  onTap: (int index, String label, {String? value}) {
                    _transferFile(context, filename, videoExtension);
                  }),
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
                  icon: const Icon(Icons.change_circle_outlined),
                  onTap: (int index, String label, {String? value}) {
                    _transferFile(context, filename, audioExtension);
                  }),
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
                  icon: const Icon(Icons.change_circle_outlined),
                  onTap: (int index, String label, {String? value}) {
                    _transferFile(context, filename, imageExtension);
                  }),
            );
          }
        }
      }

      await MenuUtil.popModalBottomSheet(
        context,
        actions: filePopActionData,
      );
    }
  }

  /// 当前媒体文件转换成新的格式，使用新的扩展名
  Future<String?> _transferFile(
      BuildContext context, String filename, String extension) async {
    int pos = filename.lastIndexOf('.');
    String output = '${filename.substring(0, pos)}.$extension';
    String command = FFMpegHelper.buildCommand(
      input: filename,
      output: output,
    );
    FFMpegHelperSession session = await FFMpegHelper.runAsync([command],
        completeCallback: (FFMpegHelperSession session) async {});
    ffmpegSessions[filename] = session;
    List<ReturnCode?> returnCode = await session.getReturnCode();
    bool? success = returnCode.firstOrNull?.isValueSuccess();
    if (success != null && success) {
      return output;
    }

    return null;
  }

  Future<Widget?> _buildSessionStateWidget(
      BuildContext context, String filename) async {
    FFMpegHelperSession? session = ffmpegSessions[filename];
    Widget? stateWidget;
    if (session == null) {
      return null;
    }
    SessionState state = await session.getState();
    if (state == SessionState.running) {
      stateWidget = IconButton(
          onPressed: () {
            session.cancelSession();
          },
          icon: const Icon(
            Icons.run_circle_outlined,
            color: Colors.yellow,
          ));
    }
    if (state == SessionState.completed) {
      stateWidget = const Icon(
        Icons.check_circle_outline,
        color: Colors.green,
      );
    }
    if (state == SessionState.failed) {
      stateWidget = IconButton(
          onPressed: () {
            session.cancelSession();
          },
          icon: const Icon(
            Icons.remove_circle_outline,
            color: Colors.red,
          ));
    }

    return stateWidget;
  }

  Future<Widget> _buildTaskStateWidget(BuildContext context) async {
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
      Widget? stateWidget = await _buildSessionStateWidget(context, filename);
      if (stateWidget != null) {
        TileData tile = TileData(
          title: FileUtil.filename(filename),
          subtitle: '$length',
          selected: selected,
          suffix: stateWidget,
        );
        tileData.add(tile);
      }
    }

    return DataListView(
      itemCount: tileData.length,
      itemBuilder: (BuildContext context, int index) {
        return tileData[index];
      },
    );
  }

  List<ActionData> _buildActions(BuildContext context) {
    List<ActionData> children = [
      ActionData(
          label: AppLocalizations.t('edit'),
          icon: const Icon(Icons.edit),
          onTap: (int index, String label, {String? value}) {
            String? filename = playlistController.current?.filename;
            if (filename == null) {
              return;
            }
            String? mimeType = FileUtil.mimeType(filename);
            if (mimeType != null) {
              if (mimeType.startsWith('image')) {
                indexWidgetProvider.push('image_editor');
              }
              if (mimeType.startsWith('video')) {
                indexWidgetProvider.push('video_editor');
              }
            }
          }),
      ActionData(
        label: AppLocalizations.t('transfer'),
        onTap: (int index, String label, {String? value}) async {
          String? filename = playlistController.current?.filename;
          if (filename != null) {
            _showTransferFileMenu(context, filename);
          }
        },
        icon: const Icon(Icons.transform_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('information'),
        onTap: (int index, String label, {String? value}) async {
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
      ),
      ActionData(
        label: AppLocalizations.t('formats'),
        onTap: (int index, String label, {String? value}) async {
          output.value = await FFMpegUtil.formats();
          show(context, 'formats');
        },
        icon: const Icon(Icons.format_align_center_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('encoders'),
        onTap: (int index, String label, {String? value}) async {
          output.value = await FFMpegUtil.encoders();
          show(context, 'encoders');
        },
        icon: const Icon(Icons.qr_code),
      ),
      ActionData(
        label: AppLocalizations.t('decoders'),
        onTap: (int index, String label, {String? value}) async {
          output.value = await FFMpegUtil.decoders();
          show(context, 'decoders');
        },
        icon: const Icon(Icons.qr_code_scanner),
      ),
      ActionData(
        label: AppLocalizations.t('help'),
        onTap: (int index, String label, {String? value}) async {
          output.value = await FFMpegUtil.help();
          show(context, 'help');
        },
        icon: const Icon(Icons.help_outline),
      ),
    ];

    return children;
  }

  show(BuildContext context, String title) {
    DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              child: Column(children: [
            AppBarWidget(
              title: AutoSizeText(AppLocalizations.t(title)),
            ),
            Expanded(
                child: SingleChildScrollView(
                    child: Container(
                        padding: const EdgeInsets.all(15.0),
                        child: AutoSizeText(output.value ?? '')))),
          ]));
        });
  }

  Widget _buildFfmpegMedia(BuildContext context) {
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
          return ValueListenableBuilder(
            valueListenable: ffmpegPresent,
            builder: (BuildContext context, value, Widget? child) {
              if (value) {
                return FutureBuilder(
                  future: _buildTaskStateWidget(context),
                  builder:
                      (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                    Widget? child = snapshot.data;
                    if (child != null) {
                      return child;
                    }
                    return LoadingUtil.buildLoadingIndicator();
                  },
                );
              }
              return FFMpegInstallWidget(
                onDownloadComplete: () {
                  checkFFMpeg();
                },
              );
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
                tooltip: AppLocalizations.t('Ffmpeg task'),
                onPressed: () async {
                  await swiperController.move(1);
                },
                icon: const Icon(Icons.task_alt_outlined),
              ),
              IconButton(
                tooltip: AppLocalizations.t('Ffmpeg actions'),
                onPressed: () {
                  List<ActionData> actions = _buildActions(context);
                  MenuUtil.popModalBottomSheet(
                    context,
                    actions: actions,
                  );
                },
                icon: const Icon(Icons.perm_media_outlined),
              ),
              IconButton(
                tooltip: AppLocalizations.t('Playlist action'),
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
      child: _buildFfmpegMedia(context),
    );
  }
}
