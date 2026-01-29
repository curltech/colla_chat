import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/adaptive_container.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_media_widget.dart';
import 'package:colla_chat/widgets/media_editor/image_editor_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_player_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/pages/media/platform_video_player_widget.dart';
import 'package:colla_chat/widgets/media_editor/video_editor_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media_editor/video_renderer_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//媒体页面
class MediaWidget extends StatelessWidget with TileDataMixin {
  final PlatformVideoPlayerWidget videoPlayerWidget =
      PlatformVideoPlayerWidget();
  final PlatformAudioPlayerWidget audioPlayerWidget =
      PlatformAudioPlayerWidget();
  final PlatformAudioRecorderWidget audioRecorderWidget =
      PlatformAudioRecorderWidget();
  final FFMpegMediaWidget ffmpegMediaWidget = FFMpegMediaWidget();
  final ImageEditorWidget imageEditorWidget = ImageEditorWidget();
  final VideoEditorWidget videoEditorWidget = VideoEditorWidget();
  final VideoRendererWidget videoRendererWidget = VideoRendererWidget();
  late final List<TileDataMixin> mediaTileDataMixins = [
    videoPlayerWidget,
    audioPlayerWidget,
    audioRecorderWidget,
    imageEditorWidget,
    ffmpegMediaWidget,
    videoEditorWidget,
    videoRendererWidget
  ];
  late final Map<TileData, List<TileData>> mediaTileData;
  AdaptiveContainerController? controller;
  final ValueNotifier<int> index = ValueNotifier<int>(0);

  MediaWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'media';

  @override
  IconData get iconData => Icons.perm_media;

  @override
  String get title => 'Media';

  @override
  Widget build(BuildContext context) {
    Widget provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
        builder:
            (context, appDataProvider, indexWidgetProvider, myself, child) {
      ContainerType containerType = ContainerType.carousel;
      if (appDataProvider.landscape && appDataProvider.bodyWidth == 0) {
        containerType = ContainerType.resizeable;
      }
      controller = AdaptiveContainerController(
        containerType: containerType,
        pixels: 380,
      );
      var mediaWidget = AdaptiveContainer(
        controller: controller!,
        main: GroupDataListView(
          tileData: mediaTileData,
          onTap: (int index, String label,
              {String? subtitle, TileData? group}) async {
            this.index.value = index;
            if (!appDataProvider.landscape) {
              controller?.closeSlider();
            }

            return false;
          },
        ),
        body: ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (context, value, child) {
            return mediaTileDataMixins[index.value];
          },
        ),
      );

      return AppBarView(
          title: title,
          withLeading: true,
          rightWidgets: [
            ValueListenableBuilder(
                valueListenable: controller!.isOpen,
                builder: (BuildContext context, bool value, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      controller?.toggle();
                    },
                    isSelected: controller!.isOpen.value,
                    selectedIcon: Icon(Icons.vertical_split_outlined),
                    icon: Icon(Icons.vertical_split),
                  );
                })
          ],
          child: mediaWidget);
    });

    return provider;
  }
}
