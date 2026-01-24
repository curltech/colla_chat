import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_media_widget.dart';
import 'package:colla_chat/widgets/media_editor/image_editor_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_player_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/pages/media/platform_video_player_widget.dart';
import 'package:colla_chat/widgets/media_editor/video_editor_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/media_editor/video_renderer_widget.dart';
import 'package:flutter/material.dart';

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
  late final List<TileData> mediaTileData;

  MediaWidget({super.key}) {
    indexWidgetProvider.define(videoPlayerWidget);
    indexWidgetProvider.define(audioPlayerWidget);
    indexWidgetProvider.define(audioRecorderWidget);
    indexWidgetProvider.define(imageEditorWidget);
    indexWidgetProvider.define(ffmpegMediaWidget);
    indexWidgetProvider.define(videoEditorWidget);
    indexWidgetProvider.define(videoRendererWidget);
    List<TileDataMixin> mixins = [
      videoPlayerWidget,
      audioPlayerWidget,
      audioRecorderWidget,
      imageEditorWidget,
      ffmpegMediaWidget,
      videoEditorWidget,
      videoRendererWidget
    ];
    mediaTileData = TileData.from(mixins);
    for (var tile in mediaTileData) {
      tile.dense = true;
    }
  }

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
    Widget mediaWidget = AppBarView(
        title: title,
        withLeading: true,
        child: DataListView(
          itemCount: mediaTileData.length,
          itemBuilder: (BuildContext context, int index) {
            return mediaTileData[index];
          },
        ));

    return mediaWidget;
  }
}
