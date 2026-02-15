import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:pro_image_editor/core/enums/editor_mode.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

/// 通用的视频编辑界面，使用ffmpeg分离视频成为图像
class VideoEditorWidget extends StatelessWidget with DataTileMixin {
  VideoEditorWidget({
    super.key,
  }) {
    scrollController.addListener(_onScroll);
  }

  @override
  String get routeName => 'video_editor';

  @override
  IconData get iconData => Icons.video_camera_back_outlined;

  @override
  String get title => 'VideoEditor';

  @override
  bool get withLeading => true;

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );

  ///视频文件拆分成图像文件
  final DataListController<String> imageFileController =
      DataListController<String>();
  final ScrollController scrollController = ScrollController();
  final RxInt displayPosition = 0.obs;

  void _onScroll() {
    double offset = scrollController.offset;
    logger.i('scrolled to $offset');

    ///判断是否滚动到最底，需要加载更多数据
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      logger.i('scrolled to max');
    }
    if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
      logger.i('scrolled to min');
    }
  }

  /// 将视频文件按帧分离成图像
  Future<void> _splitImageFiles() async {
    String? videoFilename = playlistController.current?.filename;
    if (videoFilename == null) {
      return;
    }
    imageFileController.clear();
    _delete();
    int pos = displayPosition.value;
    Duration startTime = Duration(minutes: pos);
    Duration endTime = Duration(seconds: startTime.inSeconds + 10);
    List<String> commands = [];
    List<String> filenames = [];
    for (var i = 0; i < endTime.inSeconds - startTime.inSeconds; i++) {
      String filename = await FileUtil.getTempFilename(extension: 'jpg');
      filenames.add(filename);
      Duration frameTime = Duration(seconds: startTime.inSeconds + i + 1);
      String command = FFMpegHelper.buildCommand(
        input: videoFilename,
        output: filename,
        ss: frameTime.toString(),
        vframes: '1',
        update: true,
      );
      commands.add(command);
    }
    try {
      await FFMpegHelper.runAsync(commands,
          completeCallback: (FFMpegHelperSession session) async {
        imageFileController.addAll(filenames);
      });
    } catch (e) {
      DialogUtil.error(content: '$e');
    }
  }

  void _delete() {
    List<String> filenames = imageFileController.data;
    for (var filename in filenames) {
      File(filename).delete();
    }
  }

  SliderThemeData _buildSliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
        trackShape: null,
        //轨道的形状
        trackHeight: 2,
        //trackHeight：滑轨的高度

        activeTrackColor: myself.primary,
        //已滑过轨道的颜色
        inactiveTrackColor: Colors.grey,
        //未滑过轨道的颜色

        thumbColor: myself.primary,
        //滑块中心的颜色（小圆头的颜色）
        overlayColor: Colors.greenAccent,
        //滑块边缘的颜色

        thumbShape: const RoundSliderThumbShape(
          //可继承SliderComponentShape自定义形状
          disabledThumbRadius: 8, //禁用时滑块大小
          enabledThumbRadius: 8, //滑块大小
        ),
        overlayShape: const RoundSliderOverlayShape(
          //可继承SliderComponentShape自定义形状
          overlayRadius: 8, //滑块外圈大小
        ));
  }

  Widget _buildSeekBar(BuildContext context) {
    Widget seekBar = Obx(
      () {
        return Slider(
          value:
              displayPosition.value < 0 ? 0 : displayPosition.value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '${displayPosition.value}',
          activeColor: myself.primary,
          inactiveColor: Colors.grey,
          secondaryActiveColor: myself.primary,
          thumbColor: myself.primary,
          onChanged: (double value) {
            displayPosition(value.toInt());
            _splitImageFiles();
          },
        );
      },
    );
    seekBar = SliderTheme(
      data: _buildSliderTheme(context),
      child: seekBar,
    );

    return seekBar;
  }

  Widget _buildImageSlide(BuildContext context) {
    return Obx(() {
      List<Widget> children = [];
      String? current = imageFileController.current;
      for (String imageFile in imageFileController.data) {
        Widget image = InkWell(
          child: Container(
              decoration: current == imageFile
                  ? BoxDecoration(
                      border: Border.all(width: 2, color: myself.primary))
                  : null,
              padding: EdgeInsets.zero,
              child: Card(
                  elevation: 0.0,
                  margin: EdgeInsets.zero,
                  shape: const ContinuousRectangleBorder(),
                  child: ImageUtil.buildImageWidget(
                      imageContent: imageFile,
                      height: 80,
                      fit: BoxFit.contain))),
          onTap: () {
            imageFileController.current = imageFile;
          },
        );
        children.add(image);
      }
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          child: Wrap(
            children: children,
          ));
    });
  }

  Widget _buildVideoEditor(BuildContext context) {
    Widget mediaView = Column(children: [
      Expanded(child: Obx(() {
        String? filename = imageFileController.current;
        if (filename == null) {
          return nilBox;
        }
        return ProImageEditor.file(File(filename),
            key: UniqueKey(),
            callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List bytes) async {
              bool? confirm = await DialogUtil.confirm(
                context: context,
                title: 'Save as',
                content: filename,
              );
              if (confirm != null && confirm) {
                await FileUtil.writeFileAsBytes(bytes, filename);
                DialogUtil.info(content: 'Save file:$filename successfully');
              }
            }, onCloseEditor: (EditorMode mode) {
              imageFileController.clear();
            }));
      })),
      _buildSeekBar(context),
      ListenableBuilder(
          listenable: playlistController.currentIndex!,
          builder: (BuildContext context, Widget? child) {
            return _buildImageSlide(context);
          }),
    ]);

    return Center(
      child: mediaView,
    );
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
      IconButton(
        tooltip: AppLocalizations.t('More'),
        onPressed: () {
          playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    ];

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarAdaptiveView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      main: playlistWidget,
      body: _buildVideoEditor(context),
    );
  }
}
