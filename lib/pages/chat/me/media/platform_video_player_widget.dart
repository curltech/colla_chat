import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

///平台标准的video_player的实现，缺省采用webview
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  AbstractMediaPlayerController mediaPlayerController =
      MediaKitVideoPlayerController();
  final SwiperController swiperController = SwiperController();

  PlatformVideoPlayerWidget({
    super.key,
  }) {
    if (platformParams.windows) {
      WindowsVideoPlayer.registerWith();
    }
  }

  @override
  State createState() => _PlatformVideoPlayerWidgetState();

  @override
  String get routeName => 'video_player';

  @override
  IconData get iconData => Icons.videocam;

  @override
  String get title => 'VideoPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformVideoPlayerWidgetState extends State<PlatformVideoPlayerWidget> {
  ValueNotifier<int> index = ValueNotifier<int>(0);

  @override
  void initState() {
    widget.swiperController.addListener(_update);
    super.initState();
  }

  _update() {
    index.value = widget.swiperController.index;
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [
      ValueListenableBuilder(
          valueListenable: index,
          builder: (BuildContext context, int index, Widget? child) {
            if (index == 0) {
              return IconButton(
                tooltip: AppLocalizations.t('Video player'),
                onPressed: () async {
                  await widget.swiperController.move(1);
                  this.index.value = 1;
                },
                icon: const Icon(Icons.video_call),
              );
            } else {
              return IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () async {
                  await widget.swiperController.move(0);
                  this.index.value = 0;
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              );
            }
          }),
      const SizedBox(
        width: 5.0,
      )
    ];
    return children;
  }

  @override
  Widget build(BuildContext context) {
    PlatformMediaPlayer platformMediaPlayer = PlatformMediaPlayer(
      showPlaylist: true,
      mediaPlayerController: widget.mediaPlayerController,
      swiperController: widget.swiperController,
    );
    List<Widget>? rightWidgets = _buildRightWidgets();

    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformMediaPlayer,
    );
  }

  @override
  void dispose() {
    widget.mediaPlayerController.close();
    widget.swiperController.removeListener(_update);
    super.dispose();
  }
}
