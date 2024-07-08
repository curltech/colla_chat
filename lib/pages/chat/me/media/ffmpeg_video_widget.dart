import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/ffmpeg.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:ffmpeg_kit_flutter/abstract_session.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/session_state.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/state_manager.dart';

class FfmpegVideoWidget extends StatefulWidget with TileDataMixin {
  FfmpegVideoWidget({
    super.key,
  });

  @override
  State createState() => _FfmpegVideoWidgetState();

  @override
  String get routeName => 'ffmpeg_video';

  @override
  IconData get iconData => Icons.video_camera_back_outlined;

  @override
  String get title => 'FfmpegVideo';

  @override
  bool get withLeading => true;
}

class _FfmpegVideoWidgetState extends State<FfmpegVideoWidget> {
  final FileType fileType = FileType.custom;
  final Set<String> videoExtensions = {
    'mp4',
    '3gp',
    'm4a',
    'mov',
    'mpeg',
    'aac',
    'rmvb',
    'avi',
    'wmv',
    'mkv',
    'mpg',
  };
  final Set<String> audioExtensions = {
    'mp3',
    'wav',
    'mp4',
    'm4a',
  };
  final Set<String> imageExtensions = {
    'jpg',
    'JPG',
    'png',
    'PNG',
    'bmp',
    'BMP',
    'webp',
  };
  String? output;
  bool gridMode = false;
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);
  DataListController<String> fileController = DataListController<String>();
  final Set<String> allowedExtensions = {};
  Map<String, FFmpegSession> ffmpegSessions = {};

  @override
  void initState() {
    super.initState();
    fileController.addListener(_update);
    allowedExtensions.addAll(videoExtensions);
    allowedExtensions.addAll(audioExtensions);
    allowedExtensions.addAll(imageExtensions);
  }

  _update() {
    _buildTileData();
  }

  _onSelectFile(int index, String filename, {String? subtitle}) async {
    List<ActionData> filePopActionData = [];
    String? mimeType = FileUtil.mimeType(filename);
    if (mimeType != null) {
      if (mimeType.startsWith('video')) {
        for (var videoExtension in videoExtensions) {
          filePopActionData.add(
            ActionData(
                label: videoExtension,
                tooltip: 'convert to $videoExtension',
                icon: const Icon(Icons.change_circle_outlined)),
          );
        }
      } else if (mimeType.startsWith('audio')) {
        if (mimeType.startsWith('audio')) {
          for (var videoExtension in videoExtensions) {
            filePopActionData.add(
              ActionData(
                  label: videoExtension,
                  tooltip: 'convert to $videoExtension',
                  icon: const Icon(Icons.change_circle_outlined)),
            );
          }
        } else if (mimeType.startsWith('image')) {
          if (mimeType.startsWith('image')) {
            for (var videoExtension in videoExtensions) {
              filePopActionData.add(
                ActionData(
                    label: videoExtension,
                    tooltip: 'convert to $videoExtension',
                    icon: const Icon(Icons.change_circle_outlined)),
              );
            }
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
    String? filename = fileController.current;
    if (filename == null) {
      return null;
    }
    int pos = filename.lastIndexOf('.');
    String output = '${filename.substring(0, pos)}.$label';
    FFmpegSession session = await FfmpegUtil.convert(
        input: filename,
        output: output,
        completeCallback: (FFmpegSession session) async {
          _buildTileData();
        });
    ffmpegSessions[filename] = session;
    _buildTileData();
    ReturnCode? returnCode = await session.getReturnCode();
    bool? success = returnCode?.isValueSuccess();
    if (success != null && success) {
      return output;
    }

    return null;
  }

  Future<void> _buildTileData() async {
    List<String> filenames = fileController.data.toList();
    List<TileData> tileData = [];
    for (var filename in filenames) {
      File file = File(filename);
      bool exist = file.existsSync();
      if (!exist) {
        continue;
      }
      var length = file.lengthSync();
      bool selected = false;
      String? current = fileController.current;
      if (current != null) {
        if (current == filename) {
          selected = true;
        }
      }
      Widget? thumbnailWidget;
      String? mimeType = FileUtil.mimeType(filename);
      if (mimeType != null) {
        if (mimeType.startsWith('video')) {
          try {
            Uint8List? data;
            if (filename.endsWith('mp4')) {
              data = await VideoUtil.getByteThumbnail(videoFile: filename);
            } else {
              data = await FfmpegUtil.thumbnail(videoFile: filename);
            }
            if (data != null) {
              thumbnailWidget = ImageUtil.buildMemoryImageWidget(
                data,
                fit: BoxFit.cover,
              );
            }
          } catch (e) {
            logger.e('thumbnailData failure:$e');
          }
        } else if (mimeType.startsWith('audio')) {
        } else if (mimeType.startsWith('image')) {
          Uint8List? data = await FileUtil.readFileAsBytes(filename);
          if (data != null) {
            thumbnailWidget = ImageUtil.buildMemoryImageWidget(
              data,
              fit: BoxFit.cover,
            );
          }
        }
      }
      FFmpegSession? session = ffmpegSessions[filename];
      Widget? suffix;
      if (session != null) {
        SessionState state = await session.getState();
        if (state == SessionState.running) {
          suffix = IconButton(
              onPressed: () {
                session.cancel();
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
      }
      TileData tile = TileData(
        prefix: thumbnailWidget,
        title: FileUtil.filename(filename),
        subtitle: '$length',
        selected: selected,
        suffix: suffix,
        onTap: _onSelectFile,
      );
      tileData.add(tile);
    }

    this.tileData.value = tileData;
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [];
    children.add(IconButton(
      tooltip: AppLocalizations.t('information'),
      onPressed: () async {
        String? current = fileController.current;
        if (current != null) {
          MediaInformation? info =
              await FfmpegUtil.getMediaInformation(current);
          if (info != null) {
            output = info.getAllProperties()!.toString();
            show(context, 'information');
          }
        }
      },
      icon: const Icon(Icons.info_outline),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('formats'),
      onPressed: () async {
        output = await FfmpegUtil.formats();
        show(context, 'formats');
      },
      icon: const Icon(Icons.format_align_center_outlined),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('encoders'),
      onPressed: () async {
        output = await FfmpegUtil.encoders();
        show(context, 'encoders');
      },
      icon: const Icon(Icons.qr_code),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('decoders'),
      onPressed: () async {
        output = await FfmpegUtil.decoders();
        show(context, 'decoders');
      },
      icon: const Icon(Icons.qr_code_scanner),
    ));
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('help'),
        onPressed: () async {
          output = await FfmpegUtil.help();
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
            AppBarWidget.buildAppBar(
              context,
              title: CommonAutoSizeText(AppLocalizations.t(title)),
            ),
            Expanded(
                child: SingleChildScrollView(
                    child: CommonAutoSizeText(output ?? ''))),
          ]));
        });
  }

  Future<void> filePicker({
    String? dialogTitle,
    bool directory = false,
    String? initialDirectory,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    if (directory) {
      String? path = await FileUtil.directoryPathPicker(
          dialogTitle: dialogTitle, initialDirectory: initialDirectory);
      if (path != null) {
        Directory dir = Directory(path);
        List<FileSystemEntity> entries = dir.listSync();
        if (entries.isNotEmpty) {
          for (FileSystemEntity entry in entries) {
            String? extension = FileUtil.extension(entry.path);
            if (extension == null) {
              continue;
            }
            if (fileController.data.contains(entry.path)) {
              continue;
            }
            bool? contain = this.allowedExtensions.contains(extension);
            if (contain) {
              fileController.add(entry.path, notify: false);
            }
          }
          fileController.currentIndex = fileController.data.length - 1;
          fileController.notifyListeners();
        }
      }
    } else {
      final xfiles = await FileUtil.pickFiles(
          allowMultiple: allowMultiple,
          type: fileType,
          allowedExtensions: this.allowedExtensions.toList());
      if (xfiles.isNotEmpty) {
        for (var xfile in xfiles) {
          if (fileController.data.contains(xfile.path)) {
            continue;
          }
          fileController.add(xfile.path, notify: false);
        }
        fileController.currentIndex = fileController.data.length - 1;
      }
    }
  }

  ///选择文件加入播放列表
  _addFiles({bool directory = false}) async {
    try {
      await filePicker(directory: directory);
    } catch (e) {
      if (mounted) {
        DialogUtil.error(context, content: 'add media file failure:$e');
      }
    }
  }

  ///播放列表按钮
  Widget _buildConvertFilesButton(BuildContext context) {
    return Column(
      children: [
        ButtonBar(
          alignment: MainAxisAlignment.start,
          children: [
            IconButton(
              color: myself.primary,
              icon: Icon(
                gridMode ? Icons.list : Icons.grid_on,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  gridMode = !gridMode;
                });
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
                _addFiles(directory: true);
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
                _addFiles();
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
                await fileController.clear();
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
                var currentIndex = fileController.currentIndex;
                if (currentIndex != -1) {
                  ffmpegSessions.remove(fileController.current);
                  await fileController.delete(index: currentIndex);
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
          if (gridMode) {
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
                          tile.prefix ?? Container(),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children)
                        ],
                      )));
              thumbnails.add(thumbnail);
            }

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
                        fileController.currentIndex = index;
                        var title = tileData[index].title;
                        var fn = tileData[index].onTap;
                        if (fn != null) {
                          fn(index, title);
                        }
                      });
                });
          } else {
            return DataListView(
              onTap: (int index, String title,
                  {TileData? group, String? subtitle}) {
                fileController.currentIndex = index;
              },
              itemCount: tileData.length,
              itemBuilder: (BuildContext context, int index) {
                return tileData[index];
              },
            );
          }
        });
  }

  Widget _buildConvertFilesWidget(BuildContext context) {
    return Column(children: [
      _buildConvertFilesButton(context),
      Expanded(
          child: FutureBuilder(
              future: _buildThumbnailView(context),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                Widget? fileWidgets = snapshot.data;
                if (fileWidgets == null) {
                  return Container();
                }
                return fileWidgets;
              })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();

    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: _buildConvertFilesWidget(context),
    );
  }

  @override
  void dispose() {
    fileController.removeListener(_update);
    super.dispose();
  }
}
