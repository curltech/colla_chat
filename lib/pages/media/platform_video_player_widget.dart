import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_video_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

///平台标准的video_player的实现，缺省采用MediaKit
class PlatformVideoPlayerWidget extends StatelessWidget with DataTileMixin {
  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    onSelected: _onSelected,
    playlistController: playlistController,
  );
  late final PlatformVideoPlayer platformVideoPlayer = PlatformVideoPlayer(
    playlistController: playlistController,
  );

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
    List<String>? filenames,
  }) {
    if (filenames != null) {
      playlistController.rootMediaSourceController
          .addMediaFiles(filenames: filenames);
    }
  }

  void _onSelected(int index, String filename) {
    // swiperController.move(1);
  }

  List<Widget> _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    children.add(IconButton(
      tooltip: AppLocalizations.t('Play'),
      onPressed: () async {
        platformVideoPlayer.play();
      },
      icon: const Icon(Icons.play_circle_outline_outlined),
    ));
    children.add(IconButton(
      tooltip: AppLocalizations.t('Toggle'),
      onPressed: () async {
        platformVideoPlayer.toggleCrossAxisCount();
      },
      icon: const Icon(Icons.toggle_off_outlined),
    ));
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('Close all'),
        onPressed: () async {
          platformVideoPlayer.close();
        },
        icon: const Icon(Icons.close),
      ),
    );
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('More'),
        onPressed: () {
          playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    );

    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets(context);

    return AppBarAdaptiveView(
      title: title,
      withLeading: true,
      helpPath: routeName,
      rightWidgets: rightWidgets,
      main: playlistWidget,
      body: platformVideoPlayer,
    );
  }
}
