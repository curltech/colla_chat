import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_video_player.dart';
import 'package:flutter/material.dart';

///平台标准的video_player的实现，缺省采用MediaKit
class PlatformVideoPlayerWidget extends StatelessWidget with DataTileMixin {
  final PlatformVideoPlayer platformVideoPlayer = PlatformVideoPlayer();

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
  });

  List<Widget> _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: platformVideoPlayer.index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return IconButton(
              tooltip: AppLocalizations.t('Video player'),
              onPressed: () async {
                platformVideoPlayer.controller.move(1);
                platformVideoPlayer.play();
              },
              icon: const Icon(Icons.video_call),
            );
          } else {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () async {
                  platformVideoPlayer.controller.move(0);
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              ),
              IconButton(
                tooltip: AppLocalizations.t('Toggle'),
                onPressed: () async {
                  platformVideoPlayer.toggleCrossAxisCount();
                },
                icon: const Icon(Icons.toggle_off_outlined),
              ),
            ]);
          }
        });
    children.add(btn);
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('Close'),
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
          platformVideoPlayer.playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    );

    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets(context);

    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformVideoPlayer,
    );
  }
}
