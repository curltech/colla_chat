import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

///平台标准的video_player的实现，缺省采用webview
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  AbstractMediaPlayerController mediaPlayerController =
      WebViewVideoPlayerController();
  final SwiperController swiperController = SwiperController();

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
  @override
  void initState() {
    super.initState();
  }

  List<Widget>? _buildRightWidgets() {
    List<bool> isSelected = const [true, false];
    if (widget.mediaPlayerController is OriginVideoPlayerController) {
      isSelected = const [false, true];
    }
    var toggleWidget = ToggleButtons(
      selectedBorderColor: Colors.white,
      borderColor: Colors.grey,
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          setState(() {
            widget.mediaPlayerController = WebViewVideoPlayerController();
          });
        } else if (newIndex == 1) {
          setState(() {
            widget.mediaPlayerController = OriginVideoPlayerController();
          });
        }
      },
      children: const <Widget>[
        Icon(
          Icons.web_outlined,
          color: Colors.white,
        ),
        Icon(
          Icons.video_call_outlined,
          color: Colors.white,
        ),
      ],
    );
    List<Widget> children = [
      IconButton(
        onPressed: () {
          widget.swiperController.next();
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
      toggleWidget,
      const SizedBox(
        width: 5.0,
      )
    ];
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();
    PlatformMediaPlayer platformMediaPlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      mediaPlayerController: widget.mediaPlayerController,
      swiperController: widget.swiperController,
    );
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
    super.dispose();
  }
}
