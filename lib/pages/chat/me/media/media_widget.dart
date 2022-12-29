import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_audio_player_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/pages/chat/me/media/platform_video_player_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/local_auth.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//媒体页面
class MediaWidget extends StatelessWidget with TileDataMixin {
  final PlatformVideoPlayerWidget videoPlayerWidget =
      PlatformVideoPlayerWidget();
  final PlatformAudioPlayerWidget audioPlayerWidget =
      const PlatformAudioPlayerWidget();
  final PlatformAudioRecorderWidget audioRecorderWidget =
      PlatformAudioRecorderWidget();
  late final Widget child;

  MediaWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(videoPlayerWidget);
    indexWidgetProvider.define(audioPlayerWidget);
    indexWidgetProvider.define(audioRecorderWidget);
    List<TileDataMixin> mixins = [
      videoPlayerWidget,
      audioPlayerWidget,
      audioRecorderWidget,
    ];
    final List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
    }
    child = Expanded(child: DataListView(tileData: meTileData));
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'media';

  @override
  Icon get icon => const Icon(Icons.perm_media);

  @override
  String get title => 'Media';

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(
        withLeading: true,
        title: Text(AppLocalizations.t(title)),
        child: child);
    return me;
  }
}
