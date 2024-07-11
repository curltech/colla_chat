import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_video_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

///平台标准的video_player的实现，缺省采用MediaKit
class PlatformVideoPlayerWidget extends StatelessWidget with TileDataMixin {
  final PlaylistController playlistController = PlaylistController();
  late final PlatformVideoPlayer platformVideoPlayer;

  @override
  String get routeName => 'video_player';

  @override
  IconData get iconData => Icons.videocam;

  @override
  String get title => 'VideoPlayer';

  @override
  bool get withLeading => true;

  PlatformVideoPlayerWidget({
    super.key,
  }) {
    platformVideoPlayer =
        PlatformVideoPlayer(playlistController: playlistController);
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: platformVideoPlayer.platformMediaPlayer.index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return IconButton(
              tooltip: AppLocalizations.t('Video player'),
              onPressed: () async {
                await platformVideoPlayer.swiperController.move(1);
              },
              icon: const Icon(Icons.video_call),
            );
          } else {
            return IconButton(
              tooltip: AppLocalizations.t('Playlist'),
              onPressed: () async {
                await platformVideoPlayer.swiperController.move(0);
              },
              icon: const Icon(Icons.featured_play_list_outlined),
            );
          }
        });
    children.add(btn);
    children.add(
      const SizedBox(
        width: 5.0,
      ),
    );
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('Close'),
        onPressed: () async {
          platformVideoPlayer.mediaPlayerController.close();
          playlistController.clear();
        },
        icon: const Icon(Icons.close),
      ),
    );

    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();

    return AppBarView(
      title: title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformVideoPlayer,
    );
  }
}
