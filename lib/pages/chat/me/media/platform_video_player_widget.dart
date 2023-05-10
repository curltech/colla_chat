import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

///平台标准的video_player的实现，缺省采用origin
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  PlatformVideoPlayerWidget({
    Key? key,
  }) : super(key: key) {
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
  VideoPlayerType videoPlayerType = VideoPlayerType.webview;
  SwiperController swiperController = SwiperController();

  @override
  void initState() {
    super.initState();
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [
      IconButton(
        onPressed: () {
          swiperController.next();
        },
        icon: const Icon(Icons.featured_play_list_outlined),
      ),
      IconButton(
        onPressed: () {
          setState(() {
            videoPlayerType = VideoPlayerType.webview;
          });
        },
        icon: const Icon(Icons.web_outlined),
      ),
      IconButton(
        onPressed: () {
          setState(() {
            videoPlayerType = VideoPlayerType.origin;
          });
        },
        icon: const Icon(Icons.video_call_outlined),
      ),
    ];
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();
    Widget child = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      videoPlayerType: videoPlayerType,
      swiperController: swiperController,
    );
    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: child,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
