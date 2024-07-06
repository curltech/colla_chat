import 'package:colla_chat/pages/chat/me/media/ffmpeg_video_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_audio_player_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_video_player_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//媒体页面
class MediaWidget extends StatelessWidget with TileDataMixin {
  final PlatformVideoPlayerWidget videoPlayerWidget =
      PlatformVideoPlayerWidget();
  final PlatformAudioPlayerWidget audioPlayerWidget =
      PlatformAudioPlayerWidget();
  final PlatformAudioRecorderWidget audioRecorderWidget =
      PlatformAudioRecorderWidget();
  final FfmpegVideoWidget ffmpegVideoWidget = FfmpegVideoWidget();
  late final List<TileData> mediaTileData;

  MediaWidget({super.key}) {
    indexWidgetProvider.define(videoPlayerWidget);
    indexWidgetProvider.define(audioPlayerWidget);
    indexWidgetProvider.define(audioRecorderWidget);
    indexWidgetProvider.define(ffmpegVideoWidget);
    List<TileDataMixin> mixins = [
      videoPlayerWidget,
      audioPlayerWidget,
      audioRecorderWidget,
      ffmpegVideoWidget,
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
    Widget child = DataListView(
      itemCount: mediaTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return mediaTileData[index];
      },
    );
    var media = AppBarView(withLeading: true, title: title, child: child);
    return media;
  }
}
